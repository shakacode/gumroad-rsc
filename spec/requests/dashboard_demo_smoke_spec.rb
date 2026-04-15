# frozen_string_literal: true

require "spec_helper"

describe "Dashboard demo routes", type: :system, js: true do
  let(:seller) { create(:named_seller, name: "Seller Example") }
  let(:demo_props) do
    {
      locale: "en-US",
      seller_display_name: seller.name,
      seller_time_zone: "UTC",
      creator_home: {
        balances: {
          balance: "$100",
          last_seven_days_sales_total: "$50",
          last_28_days_sales_total: "$150",
          total: "$500",
        },
        sales: [
          {
            id: "demo-product",
            name: "Demo product",
            sales: 12,
            revenue: 49_00,
            visits: 320,
            today: 9_00,
            last_7: 24_00,
            last_30: 49_00,
          },
        ],
        activity_items: [
          {
            type: "new_sale",
            timestamp: "2026-04-12T18:45:00Z",
            details: {
              price_cents: 49_00,
              product_name: "Demo product",
              product_unique_permalink: "demo-product",
            },
          },
          {
            type: "follower_added",
            timestamp: "2026-04-12T16:30:00Z",
            details: {
              name: "Buyer Example",
            },
          },
        ],
        stripe_verification_message: "Update your Stripe details",
        show_1099_download_notice: true,
        tax_center_enabled: true,
      },
    }
  end

  before do
    create(:user_compliance_info, user: seller, first_name: "Seller")

    allow_any_instance_of(DashboardController).to receive(:dashboard_comparison_props).and_return(demo_props)
    allow_any_instance_of(DashboardRscDemoController).to receive(:dashboard_comparison_props).and_return(demo_props)
    allow(Stripe::Balance).to receive(:retrieve).and_return(
      {
        "available" => [],
        "pending" => [],
        "connect_reserved" => [],
      }
    )

    login_as(seller)
  end

  it "renders the Inertia demo route" do
    visit dashboard_inertia_demo_path

    expect(page).to have_current_path(dashboard_inertia_demo_path, ignore_query: true)
    expect(page).to have_selector("h1", text: "Creator home Inertia demo")
    expect(page).to have_text("Client-rendered control using the same seller data and reduced surface as the RSC demo.")
    expect(page).to have_text("Update your Stripe details")
    expect(page).to have_text("Your 1099 tax form for #{Time.current.year - 1} is ready.")
    expect(page).to have_text("Best selling")
    expect(page).to have_text("Recent activity")
    expect(page).to have_text("Demo product")
    expect(page).to have_text("Buyer Example")
    expect(page).to have_link("Open RSC demo", href: dashboard_rsc_demo_path)

    within("nav[aria-label='Dashboard comparison routes']") do
      expect(page).to have_link("Inertia demo", aria: { current: "page" })
      expect(page).to have_link("RSC demo", href: dashboard_rsc_demo_path)
    end
  end

  it "renders the RSC demo route" do
    visit dashboard_rsc_demo_path

    expect(page).to have_current_path(dashboard_rsc_demo_path, ignore_query: true)
    expect(page).to have_selector("h1", text: "Creator home RSC demo")
    expect(page).to have_text("Same seller data, trimmed to the read-heavy slice where server rendering can win.")
    expect(page).to have_text("Update your Stripe details")
    expect(page).to have_text("Your 1099 tax form for #{Time.current.year - 1} is ready.")
    expect(page).to have_text("Best selling")
    expect(page).to have_text("Recent activity")
    expect(page).to have_text("Demo product")
    expect(page).to have_text("Buyer Example")
    expect(page).to have_link("Open Inertia demo", href: dashboard_inertia_demo_path)

    within("nav[aria-label='Dashboard comparison routes']") do
      expect(page).to have_link("RSC demo", aria: { current: "page" })
      expect(page).to have_link("Inertia demo", href: dashboard_inertia_demo_path)
    end
  end
end
