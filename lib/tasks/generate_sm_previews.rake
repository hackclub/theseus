namespace :assets do
  desc "generate letter template previews"
  task generate_sm_previews: :environment do
    SnailMail::Preview.generate_previews
  end
  Rake::Task["assets:precompile"].enhance(["assets:generate_sm_previews"])
end
