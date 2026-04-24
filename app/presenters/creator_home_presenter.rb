# frozen_string_literal: true

class CreatorHomePresenter
  include CurrencyHelper

  ACTIVITY_ITEMS_LIMIT = 10
  BALANCE_ITEMS_LIMIT = 3

  attr_reader :pundit_user, :seller

  def initialize(pundit_user)
    @seller = pundit_user.seller
    @pundit_user = pundit_user
  end

  def creator_home_props
    has_sale = seller.sales.not_is_bundle_product_purchase.successful_or_preorder_authorization_successful.exists?
    first_product = seller.links.visible.exists?
    getting_started_dismissed = seller.has_dismissed_getting_started_checklist?
    tax_forms = tax_forms_data

    {
      name: seller.alive_user_compliance_info&.first_name || "",
      has_sale:,
      getting_started_stats: getting_started_stats(
        has_sale:,
        first_product:,
        getting_started_dismissed:
      ),
      getting_started_dismissed:,
      balances: formatted_balances,
      sales: top_sales,
      activity_items:,
      stripe_verification_message: stripe_verification_message,
      tax_forms: tax_forms.fetch(:tax_forms),
      show_1099_download_notice: tax_forms.fetch(:show_1099_download_notice),
      tax_center_enabled: tax_forms.fetch(:tax_center_enabled)
    }
  end

  def creator_home_rsc_demo_props
    tax_forms = tax_forms_data

    {
      balances: formatted_balances,
      sales: demo_sales.presence,
      activity_items: demo_activity_items.presence,
      stripe_verification_message: stripe_verification_message,
      show_1099_download_notice: tax_forms.fetch(:show_1099_download_notice).presence,
      tax_center_enabled: tax_forms.fetch(:tax_center_enabled).presence
    }.compact
  end

  private
    def getting_started_stats(has_sale:, first_product:, getting_started_dismissed:)
      return { "first_product" => first_product } if getting_started_dismissed

      {
        "customized_profile" => seller.name.present?,
        "first_follower" => seller.followers.exists?,
        "first_product" => first_product,
        "first_sale" => has_sale,
        "first_payout" => seller.has_payout_information?,
        "first_email" => seller.installments.not_workflow_installment.send_emails.exists?,
        "purchased_small_bets" => seller.purchased_small_bets?,
      }
    end

    def formatted_balances
      balances = UserBalanceStatsService.new(user: seller).fetch[:overview]

      {
        balance: formatted_dollar_amount(balances.fetch(:balance), with_currency: seller.should_be_shown_currencies_always?),
        last_seven_days_sales_total: formatted_dollar_amount(balances.fetch(:last_seven_days_sales_total), with_currency: seller.should_be_shown_currencies_always?),
        last_28_days_sales_total: formatted_dollar_amount(balances.fetch(:last_28_days_sales_total), with_currency: seller.should_be_shown_currencies_always?),
        total: formatted_dollar_amount(balances.fetch(:sales_cents_total), with_currency: seller.should_be_shown_currencies_always?),
      }
    end

    def top_sales
      analytics = creator_home_analytics
      top_sales_data = analytics[:by_date][:sales]
        .sort_by { |_, sales| -sales&.sum }.take(BALANCE_ITEMS_LIMIT)

      # Preload products with thumbnail attachments to avoid N+1 queries
      product_permalinks = top_sales_data.map(&:first)
      products_by_permalink = seller.products
        .where(unique_permalink: product_permalinks)
        .includes(thumbnail_alive: { file_attachment: { blob: { variant_records: { image_attachment: :blob } } } })
        .select(&:alive?)
        .index_by(&:unique_permalink)

      top_sales_data.map do |product_permalink, _sales|
        product = products_by_permalink[product_permalink]
        next unless product

        {
          "id" => product.unique_permalink,
          "name" => product.name,
          "thumbnail" => product.thumbnail_alive&.url,
          "sales" => product.successful_sales_count,
          "revenue" => product.total_usd_cents,
          "visits" => product.number_of_views,
          "today" => analytics[:by_date][:totals][product.unique_permalink]&.last || 0,
          "last_7" => analytics[:by_date][:totals][product.unique_permalink]&.last(7)&.sum || 0,
          "last_30" => analytics[:by_date][:totals][product.unique_permalink]&.sum || 0,
        }
      end.compact
    end

    def demo_sales
      top_sales.filter do |product|
        product.values_at("sales", "revenue", "visits", "today", "last_7", "last_30").any?(&:nonzero?)
      end.map { |product| product.except("thumbnail") }
    end

    def creator_home_analytics
      today = Time.now.in_time_zone(seller.timezone).to_date
      CreatorAnalytics::CachingProxy.new(seller).data_for_dates(today - 30, today)
    end

    def stripe_verification_message
      return unless seller.stripe_account.present?

      seller.user_compliance_info_requests.requested.filter_map { |request| request.verification_error_message.presence }.last
    end

    def tax_forms_data
      previous_year = Time.current.prev_year.year
      tax_center_enabled = seller.tax_center_enabled?

      if tax_center_enabled
        {
          tax_center_enabled:,
          tax_forms: [],
          show_1099_download_notice: seller.user_tax_forms.for_year(previous_year).exists?
        }
      else
        tax_forms = (Time.current.year.downto(seller.created_at.year)).each_with_object({}) do |year, hash|
          url = seller.eligible_for_1099?(year) ? seller.tax_form_1099_download_url(year: year) : nil
          hash[year] = url if url.present?
        end

        {
          tax_center_enabled:,
          tax_forms:,
          show_1099_download_notice: tax_forms[previous_year].present?
        }
      end
    end

    def activity_items
      items = followers_activity_items + sales_activity_items
      items.sort_by { |item| item["timestamp"] }.last(ACTIVITY_ITEMS_LIMIT).reverse
    end

    def demo_activity_items
      activity_items.map do |item|
        details = item.fetch("details")

        {
          "type" => item.fetch("type"),
          "timestamp" => item.fetch("timestamp"),
          "details" => if item["type"] == "new_sale"
            details.slice("price_cents", "product_name", "product_unique_permalink")
          else
            details.slice("email", "name")
          end
        }
      end
    end

    # Returns an array for sales to be processed by the frontend.
    # {
    #   "type" => String ("new_sale"),
    #   "timestamp" => String (iso8601 UTC, example: "2022-05-16T01:01:01Z"),
    #   "details" => {
    #     "price_cents" => Integer,
    #     "email" => String,
    #     "full_name" => Nullable String,
    #     "product_name" => String,
    #     "product_unique_permalink" => String,
    #   }
    # }
    def sales_activity_items
      sales = seller.sales.successful.not_is_bundle_product_purchase.includes(:link).order(created_at: :desc).limit(ACTIVITY_ITEMS_LIMIT).load
      sales.map do |sale|
        {
          "type" => "new_sale",
          "timestamp" => sale.created_at.iso8601,
          "details" => {
            "price_cents" => sale.price_cents,
            "email" => sale.email,
            "full_name" => sale.full_name,
            "product_name" => sale.link.name,
            "product_unique_permalink" => sale.link.unique_permalink,
          }
        }
      end
    end

    # Returns an array for followers activity to be processed by the frontend.
    # {
    #   "type" => String (one of: "follower_added" | "follower_removed"),
    #   "timestamp" => String (iso8601 UTC, example: "2022-05-16T01:01:01Z"),
    #   "details" => {
    #     "email" => String,
    #     "name" => Nullable String,
    #   }
    # }
    def followers_activity_items
      results = ConfirmedFollowerEvent.search(
        query: { bool: { filter: [{ term: { followed_user_id: seller.id } }] } },
        sort: [{ timestamp: { order: :desc } }],
        size: ACTIVITY_ITEMS_LIMIT,
        _source: [:name, :email, :timestamp, :follower_user_id],
      ).map { |result| result["_source"] }

      # Collect followers' users in one DB query
      followers_user_ids = results.map { |result| result["follower_user_id"] }.compact.uniq
      followers_users_by_id = User.where(id: followers_user_ids).select(:id, :name, :timezone).index_by(&:id)

      results.map do |result|
        follower_user = followers_users_by_id[result["follower_user_id"]]
        {
          "type" => "follower_#{result["name"]}",
          "timestamp" => result["timestamp"],
          "details" => {
            "email" => result["email"],
            "name" => follower_user&.name,
          }
        }
      end
    end
end
