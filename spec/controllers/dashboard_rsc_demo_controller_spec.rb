# frozen_string_literal: true

require "spec_helper"
require "shared_examples/sellers_base_controller_concern"
require "shared_examples/authorize_called"

describe DashboardRscDemoController, type: :controller do
  it_behaves_like "inherits from Sellers::BaseController"

  let(:seller) { create(:named_user) }

  before do
    create(:user_compliance_info, user: seller, first_name: "Gumbot")
  end

  include_context "with user signed in as admin for seller"

  describe "GET index" do
    it_behaves_like "authorize called for action", :get, :index do
      let(:record) { :dashboard }
    end

    it "assigns the demo props and streams the RSC template" do
      allow(controller).to receive(:stream_view_containing_react_components) do |**|
        controller.render plain: "streamed"
      end

      get :index

      expect(response).to be_successful
      expect(controller).to have_received(:stream_view_containing_react_components).with(
        template: "dashboard_rsc_demo/index",
        layout: "inertia"
      )
      expect(assigns(:hide_layouts)).to be(true)
      expect(assigns(:dashboard_rsc_demo_props).keys).to include(:locale, :seller_display_name, :creator_home)
      expect(assigns(:dashboard_rsc_demo_props)[:seller_display_name]).to eq(seller.name)
      expect(assigns(:dashboard_rsc_demo_props).dig(:creator_home, :balances)).to be_present
      expect(response.headers["Server-Timing"]).to include("action_total")
      expect(response.headers["Server-Timing"]).to include("compare_props")
      expect(response.headers["Server-Timing"]).to include("compare_creator_home")
      expect(response.headers["Server-Timing"]).to include("render_dispatch")
    end

    context "when seller is suspended for TOS" do
      let(:admin_user) { create(:user) }
      let!(:product) { create(:product, user: seller) }

      before do
        create(:user_compliance_info, user: seller)
        seller.flag_for_tos_violation(author_id: admin_user.id, product_id: product.id)
        seller.suspend_for_tos_violation(author_id: admin_user.id)
        request.env["warden"].session["last_sign_in_at"] = DateTime.current.to_i
      end

      it "redirects to the products_path" do
        get :index

        expect(response).to redirect_to products_path
      end
    end
  end

  describe "#content_security_policy_nonce" do
    it "exposes the secure headers nonce through the controller helper" do
      allow(SecureHeaders).to receive(:content_security_policy_script_nonce).with(request).and_return("demo-nonce")

      expect(controller.helpers.content_security_policy_nonce).to eq("demo-nonce")
    end
  end
end
