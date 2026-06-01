# frozen_string_literal: true

class Components::Shared::Nav < Components::Base
  include Phlex::Rails::Helpers::LinkTo
  register_value_helper :request

  def view_template
    render Primer::Beta::NavList.new do |list|
      list.with_heading title: "Theseus"
      list.with_group do |group|
        group.with_heading(title: "Navigation")

        group.with_item(label: "Home", href: root_path) { |item| item.with_leading_visual_icon icon: :home }

        group.with_item(label: "Warehouse") do |item|
          item.with_leading_visual_icon icon: :organization
          item.with_item(label: "Orders", href: warehouse_orders_path) { |item| item.with_leading_visual_icon icon: :package }
          item.with_item(label: "Batches", href: warehouse_batches_path) { |item| item.with_leading_visual_icon icon: :stack }
          item.with_item(label: "SKUs", href: warehouse_skus_path) { |item| item.with_leading_visual_icon icon: :archive }
          item.with_item(label: "Purchase Orders", href: warehouse_purchase_orders_path) { |item| item.with_leading_visual_icon icon: :container }
          item.with_item(label: "Order templates", href: warehouse_templates_path) { |item| item.with_leading_visual_icon icon: :"project-template" }
        end

        group.with_item(label: "Mail") do |item|
          item.with_leading_visual_icon icon: :read
          item.with_item(label: "Letters", href: letters_path) { |item| item.with_leading_visual_icon icon: :mail }
          item.with_item(label: "Batches", href: letter_batches_path) { |item| item.with_leading_visual_icon icon: :stack }
          item.with_item(label: "Mail Scanner", href: scanner_letters_path) { |item| item.with_leading_visual_icon icon: :zap }
          item.with_item(label: "Return Addresses", href: return_addresses_path)
        end

        group.with_item(label: "Accounting") do |item|
          item.with_leading_visual_icon icon: :log
          item.with_item(label: "Tags", href: tags_path) { |item| item.with_leading_visual_icon icon: :tag }
        end

        group.with_item(label: "API") do |item|
          item.with_leading_visual_icon icon: :"arrow-both"
          item.with_item(label: "API keys", href: api_keys_path) { |item| item.with_leading_visual_icon icon: :key }
          item.with_item(label: "Letter queues", href: letter_queues_path) { |item| item.with_leading_visual_icon icon: :inbox }
          item.with_item(label: "Docs", href: api_docs_path) { |item| item.with_leading_visual_icon icon: :book }
        end

        group.with_item(label: "Settings") do |item|
          item.with_leading_visual_icon icon: :gear
          item.with_item(label: "Print settings", href: settings_qz_tray_path) { |item| item.with_leading_visual_svg { icon_svg("printer") } }
          item.with_item(label: "HCB payment", href: hcb_payment_accounts_path) { |item| item.with_leading_visual_svg { icon_svg("bank") } }
        end

        if current_user&.admin?
          group.with_item(label: "Admin") do |item|
            item.with_leading_visual_svg { icon_svg("hammer") }
            item.with_item(label: "Good job, #{current_user.username}!", href: good_job_path) { |item| item.with_leading_visual_icon icon: :briefcase }
            item.with_item(label: "Admin panel", href: admin_root_path) { |item| item.with_leading_visual_icon icon: :"list-ordered" }
            item.with_item(label: "Blaze it", href: blazer_path) { |item| item.with_leading_visual_icon icon: :flame }
          end
        end
      end

      if Rails.env.development?
        list.with_group(open: true) do |dev_group|
          dev_group.with_heading title: "Developer Tools", icon: :beaker
          dev_group.with_item(label: "Mail (not the real kind)", href: letter_opener_web_path, target: "_blank") { |item| item.with_leading_visual_icon icon: :unread }
        end
      end
    end
  end
end
