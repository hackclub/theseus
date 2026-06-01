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
          render Primer::Beta::Octicon.new(icon: :trash, size: :small)
        end
      end
    end
  end

  def render_empty_state
    div(class: "li-editor-empty", "x-show": "visibleItems().length === 0") do
      div(class: "text-center") do
        div(class: "li-editor-empty-icon") do
          render Primer::Beta::Octicon.new(icon: :package, size: :medium)
        end
        h3(class: "li-editor-empty-title") { "No items added" }
        p(class: "li-editor-empty-text") { "Click the button below to add SKUs." }
      end
    end
  end

  # SKU Select Panel

  def add_item_panel
    render sku_select_panel do |panel|
      render_add_button(panel)
      render_sku_groups(panel)
    end
  end

  def sku_select_panel
    Primer::Alpha::SelectPanel.new(
      title: "Add SKU",
      size: :large,
      fetch_strategy: :local,
      dynamic_label: false,
      select_variant: :none,
      id: "sku-select-panel"
    )
  end

  def render_add_button(panel)
    panel.with_show_button(scheme: :primary) do |btn|
      btn.with_leading_visual_icon(icon: :plus)
      @add_button_text
    end
  end

  def render_sku_groups(panel)
    skus_by_category.each do |category, category_skus|
      render_category_header(panel, category)
      category_skus.each { |sku| render_sku_item(panel, sku, category) }
    end
  end

  def render_category_header(panel, category)
    panel.with_item(
      label: (category || "uncategorized").to_s.humanize,
      disabled: true
    )
  end

  def render_sku_item(panel, sku, category)
    panel.with_item(
      label: sku.name,
      content_arguments: {
        "@click": add_item_js(sku),
        "data-filter-string": "#{sku.sku} #{sku.name} #{category}"
      }
    ) do |item|
      item.with_description do
        code { sku.sku }
        plain sku_description_text(sku)
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
        function setupSkuFilter() {
          var panel = document.getElementById('sku-select-panel');
          if (!panel) return;
          panel.filterFn = function(item, query) {
            var q = query.toLowerCase().trim();
            if (!q) return true;
            var content = item.querySelector('[data-filter-string]');
            var str = content ? content.getAttribute('data-filter-string').toLowerCase() : '';
            return str.includes(q);
          };
        }
        setupSkuFilter();
        if (window.customElements) {
          window.customElements.whenDefined('select-panel').then(setupSkuFilter);
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
          if (stock == null) return 'background: var(--bgColor-muted); color: var(--fgColor-muted);';
          if (stock <= 0) return 'background: var(--bgColor-danger-muted); color: var(--fgColor-danger); border-color: var(--borderColor-danger-emphasis);';
          if (stock < 10) return 'background: var(--bgColor-attention-muted); color: var(--fgColor-attention); border-color: var(--borderColor-attention-emphasis);';
          return 'background: var(--bgColor-success-muted); color: var(--fgColor-success); border-color: var(--borderColor-success-emphasis);';
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
