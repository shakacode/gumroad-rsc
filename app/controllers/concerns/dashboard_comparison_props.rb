# frozen_string_literal: true

module DashboardComparisonProps
  private
    def dashboard_comparison_props
      with_dashboard_comparison_timing("compare_props") do
        custom_context = with_dashboard_comparison_timing("compare_context") { RenderingExtension.custom_context(view_context) }
        creator_home = with_dashboard_comparison_timing("compare_creator_home") { CreatorHomePresenter.new(pundit_user).creator_home_rsc_demo_props }

        {
          locale: custom_context[:locale],
          seller_display_name: custom_context.dig(:current_seller, :name).presence || custom_context.dig(:logged_in_user, :name).presence || "Gumroad",
          seller_time_zone: creator_home[:activity_items].present? ? custom_context.dig(:current_seller, :time_zone, :name) : nil,
          creator_home:,
        }.compact
      end
    end
end
