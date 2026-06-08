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
    div(class: "line-items-editor", "x-data": alpine_data_json, "x-cloak": true) do
      div(class: "li-editor-border", "x-ref": "list") do
        div("x-show": "visibleItems().length > 0") do
          table(class: "li-editor-table") do
            thead(class: "li-editor-thead") do
              tr do
                th(class: "li-editor-th") { "Item" }
                th(class: "li-editor-th", style: "width: 120px;") { "Stock" }
                th(class: "li-editor-th", style: "width: 100px;") { "Quantity" }
                th(class: "li-editor-th", style: "width: 120px;") { "Unit Cost" } if @show_unit_cost
                th(class: "li-editor-th", style: "width: 50px;")
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

      div(class: "form-field") { add_item_panel }

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
    tr(class: "li-editor-row", "x-show": "!item._destroy", "x-transition.opacity": true) do
      td(class: "li-editor-td") do
        div(class: "li-editor-name", "x-text": "item.sku_name")
        code(class: "li-editor-sku", "x-text": "item.sku_code")
      end
      td(class: "li-editor-td") do
        template_tag("x-if": "item.sku_stock != null") do
          span(
            class: "li-editor-stock-badge",
            ":style": "stockStyle(item.sku_stock)",
            "x-text": "item.sku_stock + ' in stock'"
          )
        end
      end
      td(class: "li-editor-td") do
        input(
          type: "number",
          "x-model.number": "item.quantity",
          min: 1,
          class: "li-editor-qty-input"
        )
      end
      if @show_unit_cost
        td(class: "li-editor-td") do
          div(class: "li-editor-cost-group") do
            span(class: "li-editor-cost-prefix") { "$" }
            input(
              type: "number",
              "x-model": "item.unit_cost",
              min: 0,
              step: "0.01",
              placeholder: "0.00",
              class: "li-editor-cost-input"
            )
          end
        end
      end
      td(class: "li-editor-td text-right") do
        button(
          type: "button",
          class: "li-editor-remove-btn",
          "aria-label": "Remove item",
          "@click": "removeItem(item._index)"
        ) do
          plain "✕"
        end
      end
    end
  end

  def render_empty_state
    div(class: "li-editor-empty", "x-show": "visibleItems().length === 0") do
      div(class: "text-center") do
        div(class: "li-editor-empty-icon") do
          plain "📦"
        end
        h3(class: "li-editor-empty-title") { "No items added" }
        p(class: "li-editor-empty-text") { "Click the button below to add SKUs." }
      end
    end
  end

  # SKU Select Panel

  def add_item_panel
    details("is-": "popover", "position-": "bottom baseline-left", id: "sku-select-panel") do
      summary(tabindex: "0") do
        button("variant-": "green", type: "button") { "+ #{@add_button_text}" }
      end
      column( "gap-": "0", style: "max-height: 40lh; overflow-y: auto;") do
        div(style: "padding: 0.5lh 1ch;") do
          input(
            type: "text",
            placeholder: "Filter SKUs...",
            style: "width: 100%;",
            "x-ref": "skuFilter",
            "x-on:input.debounce.150ms": "filterSkus($event.target.value)"
          )
        end
        div(id: "sku-select-list") do
          skus_by_category.each do |category, category_skus|
            div(style: "padding: 0.25lh 1ch; color: var(--foreground2); font-weight: bold;") do
              plain (category || "uncategorized").to_s.humanize
            end
            category_skus.each do |sku|
              a(
                href: "#",
                style: "display: block; padding: 0.25lh 1ch;",
                "data-filter-string": "#{sku.sku} #{sku.name} #{category}",
                "@click.prevent": add_item_js(sku)
              ) do
                strong { sku.name }
                plain " "
                code { sku.sku }
                plain sku_description_text(sku)
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
          if (stock == null) return 'background: var(--background2); color: var(--foreground2);';
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
