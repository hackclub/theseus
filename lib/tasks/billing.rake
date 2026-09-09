namespace :billing do
  desc "Backfill ledger entries from historical hcb_transfer_id columns (dry run unless APPLY=1)"
  task backfill: :environment do
    Billing::Backfill.new(dry_run: ENV["APPLY"] != "1").run!
  end

  desc "Reconcile unknown / stale-pending HCB transfers now"
  task reconcile: :environment do
    Billing::Reconciler.run!.each { |r| puts "#{r.transfer.idempotency_key}: #{r.outcome} #{r.detail}" }
  end
end
