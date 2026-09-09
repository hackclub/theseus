namespace :assets do
  desc "generate letter template previews"
  task generate_sm_previews: :environment do
    SnailMail::Preview.generate_previews
  end
  Rake::Task["assets:precompile"].enhance(["assets:generate_sm_previews"])

  desc "generate a single letter template preview, e.g. rake 'assets:generate_sm_preview[macondo]'"
  task :generate_sm_preview, [:name] => :environment do |_t, args|
    name = args[:name] or abort "usage: rake 'assets:generate_sm_preview[template name]'"
    Rails.application.eager_load! # so TemplateBase.descendants includes the template in dev
    SnailMail::Preview::OUTPUT_DIR.mkpath # ensure the output dir exists on a fresh checkout
    SnailMail::Preview.generate_single_preview(name)
    puts "wrote app/frontend/images/template_previews/#{name.parameterize.underscore}_template.png"
  end
end
