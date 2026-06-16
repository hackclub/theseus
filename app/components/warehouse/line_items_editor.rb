# frozen_string_literal: true

class Components::Warehouse::LineItemsEditor < Components::Base
  def initialize(
    form:,
    line_items: nil,
    scope: :in_inventory,
    show_unit_cost: false,
    add_button_text: "Add Item"
  )
    @form = form
    @line_items = line_items || form.object.line_items
    @scope = scope
    @show_unit_cost = show_unit_cost
    @add_button_text = add_button_text
  end

  def view_template
    div("x-data": alpine_data_json, "x-cloak": true) do
      section("x-ref": "list", style: "padding:0;") do
        div("x-show": "visibleItems().length > 0") do
          table do
            thead do
              tr do
                th { "Item" }
                th(style: "width:8rem") { "Stock" }
                th(style: "width:6rem") { "Qty" }
                th(style: "width:8rem") { "Unit Cost" } if @show_unit_cost
                th(style: "width:3rem")
              end
            end
            tbody do
              template_tag("x-for": "item in items", ":key": "item._index") do
                render_line_item_row
              end
            end
          end
        end
        render_empty_state
      end

      div(style: "margin-top:0.75rem;") { add_item_panel }
      hidden_fields
      sku_filter_script
    end
  end

  private

  def template_tag(**attrs, &block)
    tag(:template, **attrs, &block)
  end

  # Line item row

  def render_line_item_row
    tr("x-show": "!item._destroy", "x-transition.opacity": true) do
      td do
        strong("x-text": "item.sku_name")
        whitespace
        code(class: "text-muted", style: "font-size:0.85em;", "x-text": "item.sku_code")
      end
      td do
        template_tag("x-if": "item.sku_stock != null") do
          span(
            class: "badge",
            ":style": "stockStyle(item.sku_stock)",
            "x-text": "item.sku_stock + ' in stock'"
          )
        end
      end
      td do
        input(
          type: "number",
          "x-model.number": "item.quantity",
          min: 1,
          style: "width:4rem;text-align:center;"
        )
      end
      if @show_unit_cost
        td do
          div(style: "display:flex;align-items:center;gap:0.2rem;") do
            span(class: "text-muted") { "$" }
            input(
              type: "number",
              "x-model": "item.unit_cost",
              min: 0,
              step: "0.01",
              placeholder: "0.00",
              style: "width:5rem;"
            )
          end
        end
      end
      td(style: "text-align:right;") do
        button(
          type: "button",
          class: "btn-sm",
          style: "color:var(--red);border-color:var(--red);",
          "aria-label": "Remove item",
          "@click": "removeItem(item._index)"
        ) { "✕" }
      end
    end
  end

  def render_empty_state
    div("x-show": "visibleItems().length === 0", style: "text-align:center;padding:2rem 1rem;color:GrayText;") do
      div(style: "font-size:2em;margin-bottom:0.5rem;") { "📦" }
      p(style: "margin:0;") do
        strong { "No items added" }
      end
      p(style: "margin:0.25rem 0 0;") { "Click the button below to add SKUs." }
    end
  end

  # SKU Select Panel

  def add_item_panel
    details(class: "popover", id: "sku-select-panel", style: "position:relative;display:inline-block;") do
      summary(tabindex: "0", class: "btn-success", style: "display:inline-flex;width:auto;") { "+ #{@add_button_text}" }
      div(style: "position:absolute;left:0;top:100%;min-width:24rem;max-height:40rem;overflow-y:auto;background:Canvas;border:1px solid var(--background2);border-radius:4px;box-shadow:0 4px 12px rgba(0,0,0,0.15);z-index:20;") do
        div(style: "padding:0.5rem;position:sticky;top:0;background:Canvas;border-bottom:1px solid var(--background2);") do
          input(
            type: "text",
            placeholder: "Filter SKUs...",
            class: "toolbar-search",
            style: "width:100%;",
            "x-ref": "skuFilter",
            "x-on:input.debounce.150ms": "filterSkus($event.target.value)"
          )
        end
        div(id: "sku-select-list") do
          skus_by_category.each do |category, category_skus|
            div(style: "padding:0.4rem 0.75rem;color:GrayText;font-size:0.8em;font-weight:600;text-transform:uppercase;letter-spacing:0.04em;") do
              plain (category || "uncategorized").to_s.humanize
            end
            category_skus.each do |sku|
              a(
                href: "#",
                class: "sku-pick-item",
                "data-filter-string": "#{sku.sku} #{sku.name} #{category}",
                "@click.prevent": add_item_js(sku)
              ) do
                strong { sku.name }
                whitespace
                code(style: "font-size:0.85em;color:GrayText;") { sku.sku }
                if (desc = sku_description_text(sku)).present?
                  span(style: "color:GrayText;font-size:0.85em;") { desc }
                end
              end
            end
          end
        end
      end
    end
  end

  def sku_description_text(sku)
    parts = [stock_display(sku), sku_cost_display(sku)].compact
    parts.any? ? "  ·  #{parts.join('  ·  ')}" : ""
  end

  def sku_cost_display(sku)
    cost = sku.actual_cost_to_hc.presence || sku.declared_unit_cost || 0
    cost_text = cost > 0 ? helpers.number_to_currency(cost) : nil
    "Cost: #{cost_text}"
  end

  def stock_display(sku)
    return nil unless sku.in_stock.present?

    if sku.in_stock <= 0
      "⚠️ Out of stock"
    elsif sku.in_stock < 10
      "⚠️ #{sku.in_stock} left"
    else
      "#{sku.in_stock} in stock"
    end
  end

  def add_item_js(sku)
    name = helpers.j(sku.name)
    code = helpers.j(sku.sku)
    stock = sku.in_stock || "null"
    cost = sku.average_po_cost || "null"
    "addItem(#{sku.id}, '#{name}', '#{code}', #{stock}, #{cost})"
  end

  def sku_filter_script
    script do
      raw <<~JS.html_safe
        function filterSkus(query) {
          var list = document.getElementById('sku-select-list');
          if (!list) return;
          var q = query.toLowerCase().trim();
          list.querySelectorAll('a[data-filter-string]').forEach(function(item) {
            if (!q) { item.style.display = ''; return; }
            var str = item.getAttribute('data-filter-string').toLowerCase();
            item.style.display = str.includes(q) ? '' : 'none';
          });
        }
      JS
    end
  end

  # Hidden form fields for Rails nested attributes

  def hidden_fields
    template_tag("x-for": "(item, idx) in items", ":key": "'field-' + item._index") do
      div do
        template_tag("x-if": "item.id") do
          input(type: "hidden", ":name": field_name("id"), ":value": "item.id")
        end

        input(type: "hidden", ":name": field_name("sku_id"), ":value": "item.sku_id")
        input(type: "hidden", ":name": field_name("quantity"), ":value": "item.quantity")

        if @show_unit_cost
          input(type: "hidden", ":name": field_name("unit_cost"), ":value": "item.unit_cost")
        end

        template_tag("x-if": "item._destroy") do
          input(type: "hidden", ":name": field_name("_destroy"), value: "1")
        end
      end
    end
  end

  def field_name(attr)
    "`#{@form.object_name}[line_items_attributes][${idx}][#{attr}]`"
  end

  # Alpine.js data

  def alpine_data_json
    initial_items = @line_items.map.with_index do |li, i|
      {
        id: li.id,
        sku_id: li.sku_id,
        sku_name: li.sku&.name,
        sku_code: li.sku&.sku,
        sku_stock: li.sku&.in_stock,
        quantity: li.quantity || 1,
        unit_cost: li.respond_to?(:unit_cost) ? li.unit_cost : nil,
        _index: i
      }
    end

    <<~JS.squish
      {
        items: #{initial_items.to_json},
        nextIndex: #{@line_items.size},
        addItem(skuId, skuName, skuCode, skuStock, skuCost) {
          const newIndex = this.nextIndex++;
          this.items.push({
            sku_id: skuId,
            sku_name: skuName,
            sku_code: skuCode,
            sku_stock: skuStock,
            quantity: 1,
            unit_cost: skuCost || '',
            _index: newIndex,
            _new: true
          });
          setTimeout(() => {
            const rows = this.$refs.list.querySelectorAll('tbody tr');
            const lastInput = rows[rows.length - 1]?.querySelector('input[type="number"]');
            if (lastInput) { lastInput.focus(); lastInput.select(); }
          }, 50);
        },
        removeItem(index) {
          const item = this.items.find(i => i._index === index);
          if (item) {
            if (item.id) { item._destroy = true; }
            else { this.items = this.items.filter(i => i._index !== index); }
          }
        },
        visibleItems() { return this.items.filter(i => !i._destroy); },
        stockStyle(stock) {
          if (stock == null) return 'background: var(--background2); color: GrayText;';
          if (stock <= 0) return 'background: var(--background1); color: var(--red);';
          if (stock < 10) return 'background: var(--background1); color: var(--yellow);';
          return 'background: var(--background1); color: var(--green);';
        }
      }
    JS
  end

  # SKU data

  def skus
    @skus ||= case @scope
              when :all then ::Warehouse::SKU.order(:sku)
              when :enabled then ::Warehouse::SKU.where(enabled: true).order(:sku)
              else ::Warehouse::SKU.in_inventory.order(:sku)
              end
  end

  def skus_by_category
    @skus_by_category ||= skus.group_by(&:category)
  end
end
