# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::MoneyNotice do
  let(:user) { create(:user) }
  let(:profile) { create(:billing_profile, user: user, organization_name: "Clubs") }
  let(:lines) do
    [
      Billing::Quote::Line.new(category: :labor, label: "labor for pkg_x", when: :now, amount_cents: 360, count: 1),
      Billing::Quote::Line.new(category: :postage, label: "postage, at cost, when it ships", when: :later, count: 1)
    ]
  end

  def render(component)
    ApplicationController.new.tap { |c| c.request = ActionDispatch::TestRequest.create }.view_context.render(component)
  end

  it "shows the payer, every line, the balance verdict, and a proceed button with the amount" do
    html = render(described_class.new(lines: lines, profiles: [ profile ], proceed: "Send to Warehouse", balances: { profile.id => 720 }))
    expect(html).to include("Billing notice").and include("Clubs")
    expect(html).to include("$3.60").and include("labor for pkg_x").and include("at cost")
    expect(html).to include("money-notice__balance--low").and include("crowbars")
    expect(html).to include("btn-money").and include("Send to Warehouse")
    expect(html).to include('name="hcb_payment_account_id"')
  end

  it "says so when the balance can't cover today" do
    html = render(described_class.new(lines: lines, profiles: [ profile ], proceed: "Go", balances: { profile.id => 100 }))
    expect(html).to include("money-notice__balance--insufficient").and include("does not cover the $3.60")
  end

  it "renders a select and one hidden balance block per profile" do
    other = create(:billing_profile, user: user, organization_id: "org_2", organization_name: "Other")
    html = render(described_class.new(lines: lines, profiles: [ profile, other ], proceed: "Go", balances: { profile.id => 100_000, other.id => nil }))
    expect(html).to include("<select").and include("Other")
    expect(html.scan(%(data-balance-for=")).size).to eq(2)
    expect(html).to include("check Other")
  end

  it "points at HCB linking when the user has no profiles" do
    html = render(described_class.new(lines: lines, profiles: [], proceed: "Go"))
    expect(html).to include("Connect your HCB account")
    expect(html).not_to include("btn-money")
  end

  it "keeps the button for work that has no payer attached" do
    html = render(described_class.new(lines: lines, profiles: [], proceed: "Send", unbilled: true))
    expect(html).to include("will not be billed").and include("btn-money").and include("unbilled")
  end

  it "flips to a refund notice" do
    html = render(described_class.new(lines: [ Billing::Quote::Line.new(category: :indicia, label: "overpaid", when: :now, amount_cents: 6120, count: 1) ], profiles: [ profile ], locked: true, refund: true, proceed: "Refund"))
    expect(html).to include("money-notice--credit").and include("Refund notice").and include("will be credited").and include("$61.20")
  end

  it "renders a preview with no button" do
    html = render(described_class.new(lines: lines, profiles: [ profile ], balances: { profile.id => 100_000 }))
    expect(html).to include("money-notice--preview").and include("Billing preview")
    expect(html).not_to include("btn-money")
  end
end
