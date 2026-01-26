# frozen_string_literal: true

class Components::StaticPages::Home < Components::Base
  def initialize(stats:)
    @stats = stats
  end

  def view_template
    div(style: "max-width: 1200px; margin: 0 auto; padding: 24px;") do
      header_section
      kpi_section
      main_section
    end
  end

  private

  attr_reader :stats

  def header_section
    header(style: "display: flex; justify-content: space-between; align-items: flex-start; flex-wrap: wrap; gap: 16px; padding-bottom: 24px; margin-bottom: 24px; border-bottom: 1px solid var(--borderColor-default, #d0d7de);") do
      div do
        h1(style: "font-size: 2rem; font-weight: 300; margin: 0;") { "Theseus" }
        p(style: "color: var(--fgColor-muted, #656d76); margin: 8px 0 0;") do
          plain "Welcome back, "
          strong { current_user&.username || "friend" }
        end
      end

      div(style: "display: flex; gap: 8px; flex-wrap: wrap;") do
        a(href: new_letter_path, class: "btn btn-primary") do
          render Primer::Beta::Octicon.new(icon: :mail, mr: 1)
          plain "Send a letter"
        end
        a(href: new_warehouse_order_path, class: "btn") do
          render Primer::Beta::Octicon.new(icon: :package, mr: 1)
          plain "Send a warehouse order"
        end
        a(href: new_letter_batch_path, class: "btn") do
          render Primer::Beta::Octicon.new(icon: :stack, mr: 1)
          plain "Create a batch"
        end
      end
    end
  end

  def kpi_section
    div(style: "margin-bottom: 32px;") do
      # Action items section
      h2(style: "font-size: 14px; font-weight: 600; color: var(--fgColor-muted, #656d76); text-transform: uppercase; letter-spacing: 0.5px; margin: 0 0 12px;") { "Needs attention" }
      div(style: "display: grid; grid-template-columns: repeat(auto-fit, minmax(160px, 1fr)); gap: 12px; margin-bottom: 24px;") do
        action_card("Orders to dispatch", stats[:orders_to_dispatch], :package, warehouse_orders_path)
        action_card("Letters to print", stats[:letters_to_print], :mail, letters_path)
        action_card("Ready to mail", stats[:letters_to_mail], :check, letters_path)
        action_card("Open batches", stats[:open_letter_batches], :inbox, letter_batches_path)
        action_card("My queued letters", stats[:my_queued_letters], :inbox, letter_queues_path) if stats[:my_queue_count].to_i > 0
      end

      # Global stats section
      h2(style: "font-size: 14px; font-weight: 600; color: var(--fgColor-muted, #656d76); text-transform: uppercase; letter-spacing: 0.5px; margin: 0 0 12px;") { "This week" }
      div(style: "display: grid; grid-template-columns: repeat(auto-fit, minmax(160px, 1fr)); gap: 12px;") do
        stat_card("In transit", stats[:orders_in_transit], :rocket, warehouse_orders_path)
        stat_card("Orders shipped", stats[:orders_shipped_this_week], :package, warehouse_orders_path)
        stat_card("Letters mailed", stats[:letters_mailed_this_week], :"paper-airplane", letters_path)
        stat_card("Letters (30d)", stats[:total_letters_this_month], :graph, letters_path)
      end
    end
  end

  def main_section
    wh = policy(::Warehouse::Order.new).index?
    div(style: "display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 24px;") do
      if wh
        warehouse_links = [
          { label: "Orders", href: warehouse_orders_path, icon: :package, check: -> { true } },
          { label: "Batches", href: warehouse_batches_path, icon: :stack, check: -> { true } },
          { label: "SKUs", href: warehouse_skus_path, icon: :archive, check: -> { policy(::Warehouse::SKU.new).index? } },
          { label: "Purchase Orders", href: warehouse_purchase_orders_path, icon: :container, check: -> { policy(::Warehouse::PurchaseOrder.new).index? } }
        ]
        link_panel("Warehouse", warehouse_links)
      end

      mail_links = [
        { label: "Letters", href: letters_path, icon: :mail, check: -> { policy(::Letter.new).index? } },
        { label: "Batches", href: letter_batches_path, icon: :stack, check: -> { policy(::Letter::Batch.new).index? } },
        { label: "Mail Scanner", href: scanner_letters_path, icon: :zap, check: -> { policy(::Letter.new).index? } },
        { label: "Return Addresses", href: return_addresses_path, icon: :home, check: -> { policy(ReturnAddress.new).index? } }
      ]
      link_panel("Mail", mail_links)

      tools_links = [
        { label: "ID Lookup", href: public_ids_path, icon: :search, check: -> { current_user&.admin? } },
        { label: "Customs Receipts", href: customs_receipts_path, icon: :"file-badge", check: -> { policy(:customs_receipt).index? } },
        { label: "Public Site", href: public_root_path, icon: :globe, check: -> { true } }
      ]
      link_panel("Tools", tools_links)
    end
  end

  def action_card(title, value, icon, href)
    has_items = value.to_i > 0
    border_color = has_items ? "var(--borderColor-attention-emphasis, #bf8700)" : "var(--borderColor-default, #d0d7de)"
    bg_color = has_items ? "var(--bgColor-attention-muted, #fff8c5)" : "var(--bgColor-default, #fff)"

    a(
      href:,
      style: "display: block; padding: 14px; background: #{bg_color}; border: 1px solid #{border_color}; border-radius: 6px; text-decoration: none; color: inherit;"
    ) do
      div(style: "display: flex; justify-content: space-between; align-items: flex-start;") do
        div do
          p(style: "font-size: 11px; color: var(--fgColor-muted, #656d76); margin: 0 0 4px; text-transform: uppercase; letter-spacing: 0.3px;") { title }
          span(style: "font-size: 28px; font-weight: 600; line-height: 1;") { value.to_s }
        end
        span(style: "color: #{has_items ? 'var(--fgColor-attention, #9a6700)' : 'var(--fgColor-muted, #656d76)'};") do
          render Primer::Beta::Octicon.new(icon:, size: :small)
        end
      end
    end
  end

  def stat_card(title, value, icon, href)
    a(
      href:,
      style: "display: block; padding: 14px; background: var(--bgColor-default, #fff); border: 1px solid var(--borderColor-default, #d0d7de); border-radius: 6px; text-decoration: none; color: inherit;"
    ) do
      div(style: "display: flex; justify-content: space-between; align-items: flex-start;") do
        div do
          p(style: "font-size: 11px; color: var(--fgColor-muted, #656d76); margin: 0 0 4px; text-transform: uppercase; letter-spacing: 0.3px;") { title }
          span(style: "font-size: 28px; font-weight: 600; line-height: 1;") { value.to_s }
        end
        span(style: "color: var(--fgColor-muted, #656d76);") do
          render Primer::Beta::Octicon.new(icon:, size: :small)
        end
      end
    end
  end

  def link_panel(title, links)
    div(style: "background: var(--bgColor-default, #fff); border: 1px solid var(--borderColor-default, #d0d7de); border-radius: 6px; overflow: hidden;") do
      div(style: "padding: 12px 16px; border-bottom: 1px solid var(--borderColor-default, #d0d7de); background: var(--bgColor-muted, #f6f8fa);") do
        h3(style: "font-size: 14px; font-weight: 600; margin: 0;") { title }
      end
      div(style: "padding: 8px 0;") do
        links.each do |link|
          next unless link[:check].call
          a(
            href: link[:href],
            style: "display: flex; align-items: center; gap: 12px; padding: 10px 16px; text-decoration: none; color: inherit;"
          ) do
            span(style: "color: var(--fgColor-muted, #656d76);") do
              render Primer::Beta::Octicon.new(icon: link[:icon], size: :small)
            end
            span(style: "font-size: 14px;") { link[:label] }
          end
        end
      end
    end
  end
end
