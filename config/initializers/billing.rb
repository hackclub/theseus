# frozen_string_literal: true

# MOCK_HCB makes Billing::Executor mark transfers completed without ever
# talking to HCB — no money moves, but every batch looks paid for. If that
# ever leaks into production it is silently free postage, so refuse to boot.
if Rails.env.production? && ENV["MOCK_HCB"].present?
  raise "MOCK_HCB is set in production; it fakes billing and must never be enabled here. Unset it and redeploy."
end
