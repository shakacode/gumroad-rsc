# frozen_string_literal: true

class DashboardRscDemoController < Sellers::BaseController
  include ReactOnRailsPro::Stream

  before_action :check_payment_details, only: :index

  def index
    authorize :dashboard

    if current_seller.suspended_for_tos_violation?
      redirect_to products_url
      return
    end

    LargeSeller.create_if_warranted(current_seller)

    @hide_layouts = true
    @dashboard_rsc_demo_props = dashboard_rsc_demo_props

    stream_view_containing_react_components(
      template: "dashboard_rsc_demo/index",
      layout: "inertia"
    )
  end

  private
    def dashboard_rsc_demo_props
      custom_context = RenderingExtension.custom_context(view_context)
      creator_home = CreatorHomePresenter.new(pundit_user).creator_home_rsc_demo_props

      {
        locale: custom_context[:locale],
        seller_display_name: custom_context.dig(:current_seller, :name).presence || custom_context.dig(:logged_in_user, :name).presence || "Gumroad",
        seller_time_zone: creator_home[:activity_items].present? ? custom_context.dig(:current_seller, :time_zone, :name) : nil,
        creator_home:,
      }.compact
    end
end
