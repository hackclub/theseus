# frozen_string_literal: true

class Views::Warehouse::SKUs::Index < Views::Base
  def initialize(warehouse_skus:, include_non_inventory: false, view: "grouped")
    @warehouse_skus = warehouse_skus
    @include_non_inventory = include_non_inventory
    @view = view
  end

  def view_template
    toolbar
    search_bar
    stats_bar
    if @view == "flat"
      flat_table
    else
      grouped_view
    end
    filter_script
  end

  private

  attr_reader :warehouse_skus

  def toolbar
    render Components::Shared::PageToolbar.new(
      title: "SKUs",
      jumpcode_path: warehouse_skus_path
    ) do
      span(class: "text-muted") { "#{warehouse_skus.count} items" }

      if @include_non_inventory
        a(href: warehouse_skus_path) { button(class: "btn-sm") { "Inventory only" } }
      else
        a(href: warehouse_skus_path(include_non_inventory: true)) { button(class: "btn-sm") { "Show all" } }
      end

      admin_tool(element: "span") do
        a(href: new_admin_warehouse_sku_path) { button(class: "btn-success btn-sm") { "+ New SKU" } }
      end
    end
  end

  def search_bar
    input(
      type: "text",
      name: "sku_search",
      placeholder: "Search by SKU, name, or description...",
      class: "toolbar-search",
      style: "width:100%;margin-bottom:0.75rem;"
    )
  end

  def stats_bar
    in_stock = warehouse_skus.count { |s| s.in_stock.to_i > 0 }
    low_stock = warehouse_skus.count { |s| s.in_stock.to_i.between?(1, 10) }
    backordered = warehouse_skus.count { |s| s.in_stock.to_i < 0 }

    div(class: "stat-filters", id: "stats-container", style: "border-bottom:none;margin-bottom:0.5rem;") do
      stat_btn("In Stock", in_stock, "in-stock", "green")
      stat_btn("Low Stock", low_stock, "low-stock", "yellow") if low_stock > 0
      stat_btn("Backordered", backordered, "backordered", "red") if backordered > 0
    end

    div(style: "display:flex;gap:0.5rem;margin-bottom:1rem;") do
      if @view == "flat"
        a(href: warehouse_skus_path(include_non_inventory: @include_non_inventory)) do
          button(class: "btn-sm") { "Grouped view" }
        end
      else
        button(id: "expand-all-btn", class: "btn-sm") { "Expand all" }
        button(id: "collapse-all-btn", class: "btn-sm") { "Collapse all" }
        a(href: warehouse_skus_path(include_non_inventory: @include_non_inventory, view: "flat")) do
          button(class: "btn-sm") { "Flat view" }
        end
      end
    end
  end

  def stat_btn(label, value, filter_key, color)
    button(
      class: "stat-filter",
      data: { filter: filter_key },
      style: "cursor:pointer;background:none;border:none;font:inherit;"
    ) do
      span(class: "stat-count", style: "color:var(--#{color})") { value.to_s }
      span(class: "stat-label") { label }
    end
  end

  # ── Grouped view ──────────────────────────────────────

  def grouped_view
    warehouse_skus.group_by(&:category).each do |category, skus|
      category_section(category, skus)
    end
  end

  def category_section(category, skus)
    in_stock = skus.count { |s| s.in_stock.to_i > 0 }
    backordered = skus.count { |s| s.in_stock.to_i < 0 }

    details(open: true, class: "sku-category", data: { category: category }) do
      summary(style: "display:flex;align-items:center;gap:0.5rem;padding:0.5rem 0;") do
        span(class: "text-muted") { category_icon(category) }
        strong { category&.humanize || "Uncategorized" }
        span(class: "badge", id: "counter-#{category}") { skus.count.to_s }
        span(class: "spacer")
        span(class: "badge badge-success", id: "label-in-stock-#{category}") { "#{in_stock} in stock" } if in_stock > 0
        span(class: "badge badge-danger", id: "label-backordered-#{category}") { "#{backordered} backordered" } if backordered > 0
      end

      table do
        thead do
          tr do
            th { "SKU" }
            th { "Name" }
            th(style: "text-align:right") { "Stock" }
            th(style: "text-align:right") { "Inbound" }
            th(style: "text-align:right") { "Cost" }
            th { "Status" }
            th(style: "text-align:center") { "" }
          end
        end
        tbody do
          skus.sort_by { |s| [s.in_stock.to_i > 0 ? 0 : 1, s.sku] }.each do |sku|
            search_text = [sku.sku, sku.name, sku.description].compact.join(" ").downcase
            tr(
              class: "sku-row",
              data: { search: search_text, status: stock_status(sku) }
            ) do
              td do
                a(href: warehouse_sku_path(sku), style: "text-decoration:none;font-weight:600;") { sku.sku }
              end
              td do
                plain sku.name
                if sku.ai_enabled
                  whitespace
                  span(class: "badge badge-info") { "AI" }
                end
                unless sku.enabled
                  whitespace
                  span(class: "badge") { "Disabled" }
                end
              end
              td(style: "text-align:right;font-variant-numeric:tabular-nums;") { sku.in_stock&.to_s || "—" }
              td(style: "text-align:right;color:GrayText;font-variant-numeric:tabular-nums;") { sku.inbound&.to_s || "—" }
              td(style: "text-align:right;font-variant-numeric:tabular-nums;") { helpers.number_to_currency(sku.declared_unit_cost) }
              td { stock_badge(sku) }
              td(style: "text-align:center") { sku_actions(sku) }
            end
          end
        end
      end
    end
  end

  # ── Flat view ─────────────────────────────────────────

  def flat_table
    table do
      thead do
        tr do
          th { "SKU" }
          th { "Name" }
          th { "Category" }
          th(style: "text-align:right") { "Stock" }
          th(style: "text-align:right") { "Inbound" }
          th(style: "text-align:right") { "Cost" }
          th { "Status" }
          th(style: "text-align:center") { "" }
        end
      end
      tbody(id: "flat-table-body") do
        warehouse_skus.each do |sku|
          search_text = [sku.sku, sku.name, sku.description].compact.join(" ").downcase
          tr(
            class: "sku-row flat-view-row",
            data: {
              search: search_text,
              status: stock_status(sku),
              sku_name: sku.sku.downcase,
              sort_name: sku.name.downcase,
              sort_cost: sku.declared_unit_cost.to_f,
              sort_stock: sku.in_stock.to_i
            }
          ) do
            td do
              a(href: warehouse_sku_path(sku), style: "text-decoration:none;font-weight:600;font-family:monospace;") { sku.sku }
            end
            td { sku.name }
            td(class: "text-muted") { sku.category&.humanize || "—" }
            td(style: "text-align:right;font-weight:600;font-variant-numeric:tabular-nums;") { sku.in_stock&.to_s || "—" }
            td(style: "text-align:right;color:GrayText;font-variant-numeric:tabular-nums;") { sku.inbound&.to_s || "—" }
            td(style: "text-align:right;font-variant-numeric:tabular-nums;") { helpers.number_to_currency(sku.declared_unit_cost) }
            td { stock_badge(sku) }
            td(style: "text-align:center") { sku_actions(sku) }
          end
        end
      end
    end
  end

  # ── Helpers ───────────────────────────────────────────

  def stock_status(sku)
    stock = sku.in_stock.to_i
    if stock > 10 then "in-stock"
    elsif stock.between?(1, 10) then "low-stock"
    elsif stock < 0 then "backordered"
    else "no-inventory"
    end
  end

  def stock_badge(sku)
    stock = sku.in_stock.to_i
    if stock > 10
      span(class: "badge badge-success") { "In stock" }
    elsif stock.between?(1, 10)
      span(class: "badge badge-warning") { "Low stock" }
    elsif stock < 0
      if sku.inbound.to_i >= stock.abs
        span(class: "badge badge-warning") { "Backordered" }
      else
        span(class: "badge badge-danger") { "Backordered" }
      end
    else
      span(class: "badge") { "No inventory" }
    end
  end

  def sku_actions(sku)
    details(class: "popover", style: "position:relative") do
      summary(tabindex: "0", class: "btn-sm") { "⋯" }
      div(style: "position:absolute;right:0;top:100%;min-width:10rem;background:Canvas;border:1px solid var(--background2);padding:0.5rem;display:flex;flex-direction:column;gap:0.25rem;z-index:10;") do
        a(href: warehouse_sku_path(sku), style: "text-decoration:none;color:inherit;") { "View details" }
        if sku.zenventory_url.present?
          a(href: sku.zenventory_url, target: "_blank", style: "text-decoration:none;color:inherit;") { "Open in Zenventory ↗" }
        end
        if current_user&.is_admin?
          a(href: edit_admin_warehouse_sku_path(sku), style: "text-decoration:none;color:inherit;") { "Edit" }
        end
      end
    end
  end

  def category_icon(category)
    { "sticker" => "📝", "poster" => "🖼", "card" => "💳", "flyer" => "📄",
      "other_printed_material" => "📄", "hardware" => "🔧", "book" => "📖",
      "swag" => "🎁", "grant" => "🎓", "prize" => "🏆" }[category.to_s] || "📦"
  end

  def filter_script
    script do
      raw <<~JS.html_safe
        (function() {
          var searchInput = document.querySelector('input[name="sku_search"]');
          var selectedFilter = null;

          function getRows() {
            return document.querySelectorAll('.sku-row');
          }
          function getCategories() {
            return document.querySelectorAll('.sku-category');
          }

          function applyFilters() {
            var query = (searchInput ? searchInput.value : '').toLowerCase().trim();
            getRows().forEach(function(row) {
              var searchText = row.dataset.search || '';
              var status = row.dataset.status || '';
              var matchSearch = !query || searchText.includes(query);
              var matchFilter = !selectedFilter || status === selectedFilter;
              row.style.display = (matchSearch && matchFilter) ? '' : 'none';
            });
            getCategories().forEach(function(cat) {
              var rows = cat.querySelectorAll('.sku-row');
              var visible = Array.from(rows).some(function(r) { return r.style.display !== 'none'; });
              cat.style.display = visible ? '' : 'none';
            });
          }

          if (searchInput) {
            searchInput.addEventListener('input', applyFilters);
          }

          document.querySelectorAll('[data-filter]').forEach(function(btn) {
            btn.addEventListener('click', function() {
              var filter = this.dataset.filter;
              if (selectedFilter === filter) {
                selectedFilter = null;
                this.classList.remove('active');
              } else {
                document.querySelectorAll('[data-filter]').forEach(function(b) { b.classList.remove('active'); });
                selectedFilter = filter;
                this.classList.add('active');
              }
              applyFilters();
            });
          });

          var expandBtn = document.getElementById('expand-all-btn');
          var collapseBtn = document.getElementById('collapse-all-btn');
          if (expandBtn) expandBtn.addEventListener('click', function() {
            getCategories().forEach(function(d) { d.open = true; });
          });
          if (collapseBtn) collapseBtn.addEventListener('click', function() {
            getCategories().forEach(function(d) { d.open = false; });
          });
        })();
      JS
    end
  end
end
