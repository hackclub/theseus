# frozen_string_literal: true

class Views::Warehouse::SKUs::Index < Views::Base
  def initialize(warehouse_skus:, include_non_inventory: false, view: 'grouped')
    @warehouse_skus = warehouse_skus
    @include_non_inventory = include_non_inventory
    @view = view
  end

  def view_template
    div(class: "page-container") do
      header_section
      search_section
      stats_section
      skus_by_category
    end
  end

  private

  attr_reader :warehouse_skus, :include_non_inventory, :view

  def header_section
    div(class: "page-header") do
      div do
        div(class: "section-title-group") do
          h1(class: "page-title") { "SKUs" }
          render Components::Shared::Jumpcode.new(path: warehouse_skus_path)
        end
        p(class: "page-subtitle") do
          plain "#{warehouse_skus.count} items"
          plain " (showing all)" if include_non_inventory
        end
      end

      div(class: "page-actions") do
        if include_non_inventory
          render Primer::Beta::Button.new(tag: :a, href: warehouse_skus_path, scheme: :secondary, size: :small) do |btn|
            btn.with_leading_visual_icon(icon: :filter)
            "Show inventory only"
          end
        else
          render Primer::Beta::Button.new(tag: :a, href: warehouse_skus_path(include_non_inventory: true), scheme: :secondary, size: :small) do |btn|
            btn.with_leading_visual_icon(icon: :filter)
            "Show all SKUs"
          end
        end

        admin_tool(element: "span") do
          render Primer::Beta::Button.new(tag: :a, href: new_admin_warehouse_sku_path, scheme: :primary) do |btn|
            btn.with_leading_visual_icon(icon: :plus)
            "New SKU"
          end
        end
      end
    end
  end

  def search_section
    div(class: "content-section") do
      render Primer::Alpha::TextField.new(
        name: "sku_search",
        label: "Search SKUs",
        visually_hide_label: true,
        placeholder: "Search by SKU, name, or description...",
        leading_visual: { icon: :search },
        full_width: true
      )
    end
  end

  def stats_section
    grouped = warehouse_skus.group_by(&:category)
    in_stock_count = warehouse_skus.count { |s| s.in_stock.to_i > 0 }
    backordered_count = warehouse_skus.count { |s| s.in_stock.to_i < 0 }
    low_stock_count = warehouse_skus.count { |s| s.in_stock.to_i.between?(1, 10) }

    div(class: "stat-pill-grid", id: "stats-container") do
      stat_pill_button("In Stock", in_stock_count, :success, "in-stock")
      stat_pill_button("Low Stock", low_stock_count, :attention, "low-stock") if low_stock_count > 0
      stat_pill_button("Backordered", backordered_count, :danger, "backordered") if backordered_count > 0
    end
  end

  def stat_pill(label, value, scheme)
    div(class: "stat-pill-filter", data: { scheme: scheme }) do
      div(class: "stat-pill-value") { value.to_s }
      div(class: "stat-pill-label") { label }
    end
  end

  def stat_pill_button(label, value, scheme, filter_key)
    button(
      class: "stat-pill-filter",
      data: { filter: filter_key, scheme: scheme }
    ) do
      div(class: "stat-pill-value") { value.to_s }
      div(class: "stat-pill-label") { label }
    end
  end

  def skus_by_category
    div(id: "sku-list") do
      if view == 'flat'
        render_flat_view
      else
        render_grouped_view
      end
      filter_script
    end
  end

  def render_grouped_view
    div(class: "view-toolbar") do
      render Primer::Beta::Button.new(
        scheme: :invisible,
        size: :small,
        id: "expand-all-btn"
      ) do |btn|
        btn.with_leading_visual_icon(icon: :"unfold")
        "Expand all"
      end
      render Primer::Beta::Button.new(
        scheme: :invisible,
        size: :small,
        id: "collapse-all-btn"
      ) do |btn|
        btn.with_leading_visual_icon(icon: :"fold")
        "Collapse all"
      end
      render Primer::Beta::Button.new(
        scheme: :invisible,
        size: :small,
        tag: :a,
        href: warehouse_skus_path(include_non_inventory: include_non_inventory, view: 'flat')
      ) do |btn|
        btn.with_leading_visual_icon(icon: :"list-unordered")
        "Flat view"
      end
    end

    warehouse_skus.group_by(&:category).each do |category, skus|
      render_category_section(category, skus)
    end
  end

  def render_flat_view
    div(class: "view-toolbar--spread") do
      div(class: "page-actions") do
        render Primer::Beta::Button.new(
          scheme: :secondary,
          size: :small,
          class: "sort-btn",
          data: { sort: "sku" }
        ) do |btn|
          "Sort: SKU"
        end
        render Primer::Beta::Button.new(
          scheme: :secondary,
          size: :small,
          class: "sort-btn",
          data: { sort: "name" }
        ) do |btn|
          "Sort: Name"
        end
        render Primer::Beta::Button.new(
          scheme: :secondary,
          size: :small,
          class: "sort-btn",
          data: { sort: "cost" }
        ) do |btn|
          "Sort: Cost"
        end
        render Primer::Beta::Button.new(
          scheme: :secondary,
          size: :small,
          class: "sort-btn",
          data: { sort: "stock" }
        ) do |btn|
          "Sort: Stock"
        end
      end
      render Primer::Beta::Button.new(
        scheme: :invisible,
        size: :small,
        tag: :a,
        href: warehouse_skus_path(include_non_inventory: include_non_inventory)
      ) do |btn|
        btn.with_leading_visual_icon(icon: :"package")
        "Grouped view"
      end
    end

    div(class: "flat-table-wrapper") do
      table(class: "flat-table") do
        thead do
          tr(class: "flat-table-head") do
            th(class: "flat-table-th") { "SKU" }
            th(class: "flat-table-th") { "Name" }
            th(class: "flat-table-th") { "Category" }
            th(class: "flat-table-th flat-table-th--right") { "Stock" }
            th(class: "flat-table-th flat-table-th--right") { "Inbound" }
            th(class: "flat-table-th flat-table-th--right") { "Cost" }
            th(class: "flat-table-th") { "Status" }
            th(class: "flat-table-th flat-table-th--center") { "Actions" }
          end
        end
        tbody(id: "flat-table-body") do
          warehouse_skus.each do |sku|
            search_text = [sku.sku, sku.name, sku.description].compact.join(" ").downcase
            stock_status = get_stock_status(sku)
            tr(
              class: "flat-view-row flat-table-row",
              data: {
                search: search_text,
                status: stock_status,
                sku_name: sku.sku.downcase,
                sort_name: sku.name.downcase,
                sort_cost: sku.declared_unit_cost.to_f,
                sort_stock: sku.in_stock.to_i
              }
            ) do
              td(class: "flat-table-td flat-table-td--mono") do
                a(href: warehouse_sku_path(sku), class: "link-reset") { sku.sku }
              end
              td(class: "flat-table-td") { sku.name }
              td(class: "flat-table-td flat-table-td--muted") { sku.category&.humanize || "Uncategorized" }
              td(class: "flat-table-td flat-table-td--right-bold") { sku.in_stock&.to_s || "—" }
              td(class: "flat-table-td flat-table-td--right-muted") { sku.inbound&.to_s || "—" }
              td(class: "flat-table-td flat-table-td--right") { helpers.number_to_currency(sku.declared_unit_cost) }
              td(class: "flat-table-td") do
                render(Primer::Beta::Label.new(scheme: get_badge_scheme(sku), size: :medium)) { get_badge_text(sku) }
              end
              td(class: "flat-table-td flat-table-td--center") do
                render_sku_actions(sku)
              end
            end
          end
        end
      end
    end
  end

  def filter_script
    script do
      raw <<~JS.html_safe
        (function() {
          const searchInput = document.querySelector('[name="sku_search"]');
          const expandBtn = document.getElementById('expand-all-btn');
          const collapseBtn = document.getElementById('collapse-all-btn');

          let selectedStatus = null;
          let currentSort = 'sku';
          let sortAscending = true;

          function getTbody() {
            return document.getElementById('flat-table-body');
          }

          function isFlat() {
            return getTbody() !== null;
          }

          function getStatPills() {
            return document.querySelectorAll('.stat-pill-filter');
          }

          function getSortBtns() {
            return document.querySelectorAll('.sort-btn');
          }

          function getCategories() {
            return document.querySelectorAll('.sku-category');
          }

          function setActivePill(pill) {
            const scheme = pill.dataset.scheme;
            const emphasisColors = {
              success: 'var(--bgColor-success-emphasis)',
              attention: 'var(--bgColor-attention-emphasis)',
              danger: 'var(--bgColor-danger-emphasis)',
              secondary: 'var(--bgColor-neutral-emphasis)'
            };

            pill.style.background = emphasisColors[scheme];
            pill.style.borderColor = emphasisColors[scheme];
            pill.style.color = 'var(--fgColor-onEmphasis)';
            pill.style.fontWeight = '700';
            pill.style.boxShadow = '0 0 0 3px rgba(0,0,0,0.1)';

            const divs = pill.querySelectorAll('div');
            divs.forEach(div => {
              div.style.color = 'var(--fgColor-onEmphasis)';
            });
          }

          function resetPill(pill) {
            const scheme = pill.dataset.scheme;
            const bgColors = {
              success: 'var(--bgColor-success-muted)',
              attention: 'var(--bgColor-attention-muted)',
              danger: 'var(--bgColor-danger-muted)',
              secondary: 'var(--bgColor-muted)'
            };
            const borderColors = {
              success: 'var(--borderColor-success-muted)',
              attention: 'var(--borderColor-attention-muted)',
              danger: 'var(--borderColor-danger-muted)',
              secondary: 'var(--borderColor-default)'
            };

            pill.style.background = bgColors[scheme];
            pill.style.borderColor = borderColors[scheme];
            pill.style.color = '';
            pill.style.fontWeight = '';
            pill.style.boxShadow = '';

            const divs = pill.querySelectorAll('div');
            divs.forEach((div, i) => {
              div.style.color = i === 0 ? '' : 'var(--fgColor-muted)';
            });
          }

          function updateDisplay() {
            const searchQuery = searchInput?.value.toLowerCase().trim() || '';

            const groupedRows = document.querySelectorAll('.sku-category .sku-row');
            groupedRows.forEach(row => {
              const searchText = row.dataset.search || '';
              const status = row.dataset.status || '';
              const matchesSearch = !searchQuery || searchText.includes(searchQuery);
              const matchesStatus = !selectedStatus || status === selectedStatus;
              const shouldShow = matchesSearch && matchesStatus;
              row.style.display = shouldShow ? '' : 'none';
            });

            getCategories().forEach(cat => {
              const visibleRows = cat.querySelectorAll('.sku-row:not([style*="display: none"])');
              cat.style.display = visibleRows.length > 0 ? '' : 'none';
              if ((searchQuery || selectedStatus) && visibleRows.length > 0) cat.open = true;
            });
          }

          function sortAndFilterFlat() {
            const tbody = getTbody();
            if (!tbody) {
              console.log('No tbody found');
              return;
            }
            // Get all tr elements - they may have classes= instead of class=
            const flatViewRows = Array.from(tbody.querySelectorAll('tr'));

            flatViewRows.sort((a, b) => {
              let aVal, bVal;

              switch(currentSort) {
                case 'sku':
                  aVal = a.dataset.sku_name || '';
                  bVal = b.dataset.sku_name || '';
                  break;
                case 'name':
                  aVal = a.dataset.sort_name || '';
                  bVal = b.dataset.sort_name || '';
                  break;
                case 'cost':
                  aVal = parseFloat(a.dataset.sort_cost || 0);
                  bVal = parseFloat(b.dataset.sort_cost || 0);
                  break;
                case 'stock':
                  aVal = parseInt(a.dataset.sort_stock || 0);
                  bVal = parseInt(b.dataset.sort_stock || 0);
                  break;
                default:
                  return 0;
              }

              if (aVal < bVal) return sortAscending ? -1 : 1;
              if (aVal > bVal) return sortAscending ? 1 : -1;
              return 0;
            });

            const searchQuery = (searchInput?.value || '').toLowerCase();
            flatViewRows.forEach(row => {
              const searchText = row.dataset.search || '';
              const status = row.dataset.status || '';
              const matchesSearch = !searchQuery || searchText.includes(searchQuery);
              const matchesStatus = !selectedStatus || status === selectedStatus;
              row.style.display = (matchesSearch && matchesStatus) ? '' : 'none';
              tbody.appendChild(row);
            });
          }

          function updateCategoryCounts() {
            if (isFlat()) return;

            document.querySelectorAll('.sku-category').forEach(category => {
              const categoryName = category.dataset.category;
              const visibleRows = Array.from(category.querySelectorAll('.sku-row:not([style*="display: none"])'));

              let inStockCount = 0;
              let backordered = 0;

              visibleRows.forEach(row => {
                const status = row.dataset.status || '';
                if (status === 'in-stock') {
                  inStockCount++;
                } else if (status === 'backordered') {
                  backordered++;
                }
              });

              const inStockLabel = document.getElementById(`label-in-stock-${categoryName}`);
              const backordeeredLabel = document.getElementById(`label-backordered-${categoryName}`);

              if (inStockLabel) {
                inStockLabel.style.display = inStockCount > 0 ? 'inline-block' : 'none';
                inStockLabel.innerText = `${inStockCount} in stock`;
              }
              if (backordeeredLabel) {
                backordeeredLabel.style.display = backordered > 0 ? 'inline-block' : 'none';
                backordeeredLabel.innerText = `${backordered} backordered`;
              }
            });
          }

          searchInput?.addEventListener('input', function(e) {
            if (isFlat()) {
              sortAndFilterFlat();
            } else {
              updateDisplay();
              updateCategoryCounts();
            }
          });

          document.addEventListener('click', function(e) {
            const pill = e.target.closest('.stat-pill-filter');
            if (pill) {
              const filter = pill.dataset.filter;
              if (selectedStatus === filter) {
                selectedStatus = null;
                resetPill(pill);
              } else {
                getStatPills().forEach(p => {
                  if (p.dataset.filter !== filter) {
                    resetPill(p);
                  }
                });
                selectedStatus = filter;
                setActivePill(pill);
              }
              if (isFlat()) {
                sortAndFilterFlat();
              } else {
                updateDisplay();
                updateCategoryCounts();
              }
            }

            const sortBtn = e.target.closest('.sort-btn');
            if (sortBtn) {
              if (currentSort === sortBtn.dataset.sort) {
                sortAscending = !sortAscending;
              } else {
                currentSort = sortBtn.dataset.sort;
                sortAscending = true;
              }
              getSortBtns().forEach(b => b.style.fontWeight = '');
              sortBtn.style.fontWeight = '700';
              sortAndFilterFlat();
            }
          });

          expandBtn?.addEventListener('click', () => getCategories().forEach(d => d.open = true));
          collapseBtn?.addEventListener('click', () => getCategories().forEach(d => d.open = false));
        })();
      JS
    end
  end

  def render_category_section(category, skus)
    in_stock = skus.count { |s| s.in_stock.to_i > 0 }
    backordered = skus.count { |s| s.in_stock.to_i < 0 }

    details(
      open: true,
      class: "sku-category mb-3",
      data: { category: category }
    ) do
      summary(class: "sku-category-summary") do
        div(class: "category-info") do
          render Primer::Beta::Octicon.new(icon: category_icon(category), size: :small, color: :muted)
          span(class: "category-name") { category&.humanize || "Uncategorized" }
          render(Primer::Beta::Counter.new(count: skus.count, scheme: :secondary, id: "counter-#{category}"))
        end
        div(class: "page-actions", id: "status-labels-#{category}") do
          if in_stock > 0
            render(Primer::Beta::Label.new(scheme: :success, size: :medium, id: "label-in-stock-#{category}")) { "#{in_stock} in stock" }
          end
          if backordered > 0
            render(Primer::Beta::Label.new(scheme: :danger, size: :medium, id: "label-backordered-#{category}")) { "#{backordered} backordered" }
          end
        end
      end

      div(class: "sku-category-body") do
        render Primer::Beta::BorderBox.new(padding: :condensed) do |box|
          skus.sort_by { |s| [s.in_stock.to_i > 0 ? 0 : 1, s.sku] }.each do |sku|
            search_text = [sku.sku, sku.name, sku.description].compact.join(" ").downcase
            stock_status = get_stock_status(sku)
            box.with_row(classes: "sku-row", data: { search: search_text, status: stock_status }) do
              render_sku_row(sku)
            end
          end
        end
      end
    end
  end

  def render_sku_row(sku)
    div(class: "sku-row-layout") do
      div(class: "sku-row-info") do
        div(class: "sku-row-badges") do
          a(href: warehouse_sku_path(sku), class: "sku-link") { sku.sku }
          stock_badge(sku)
          render(Primer::Beta::Label.new(scheme: :accent, size: :medium)) { "AI enabled" } if sku.ai_enabled
          render(Primer::Beta::Label.new(scheme: :secondary, size: :medium)) { "Disabled" } unless sku.enabled
        end
        div(class: "sku-row-name") { sku.name }
        if sku.description.present? && sku.description != sku.name
          div(class: "sku-row-desc") { sku.description }
        end
      end

      div(class: "sku-row-stats") do
        div(class: "sku-stat-col sku-stat-col--wide") do
          div(class: "sku-stat-label") { "Stock" }
          div(class: "sku-stat-value") { sku.in_stock&.to_s || "—" }
        end
        div(class: "sku-stat-col") do
          div(class: "sku-stat-label") { "Inbound" }
          div(class: "sku-stat-value sku-stat-value--muted") { sku.inbound&.to_s || "—" }
        end
        div(class: "sku-stat-col sku-stat-col--cost") do
          div(class: "sku-stat-label") { "Cost" }
          div(class: "sku-stat-value sku-stat-value--muted") { helpers.number_to_currency(sku.declared_unit_cost) }
        end

        render_sku_actions(sku)
      end
    end
  end

  def get_stock_status(sku)
    if sku.in_stock.to_i > 10
      "in-stock"
    elsif sku.in_stock.to_i.between?(1, 10)
      "low-stock"
    elsif sku.in_stock.to_i < 0
      "backordered"
    else
      "no-inventory"
    end
  end

  def get_badge_scheme(sku)
    if sku.in_stock.to_i > 10
      :success
    elsif sku.in_stock.to_i.between?(1, 10)
      :attention
    elsif sku.in_stock.to_i < 0
      :danger
    else
      :secondary
    end
  end

  def get_badge_text(sku)
    if sku.in_stock.to_i > 10
      "In stock"
    elsif sku.in_stock.to_i.between?(1, 10)
      "Low stock"
    elsif sku.in_stock.to_i < 0
      "Backordered"
    else
      "No inventory"
    end
  end

  def stock_badge(sku)
    if sku.in_stock.to_i > 10
      render(Primer::Beta::Label.new(scheme: :success, size: :medium)) { "In stock" }
    elsif sku.in_stock.to_i.between?(1, 10)
      render(Primer::Beta::Label.new(scheme: :attention, size: :medium)) { "Low stock" }
    elsif sku.in_stock.to_i < 0
      if sku.inbound.to_i >= sku.in_stock.abs
        render(Primer::Beta::Label.new(scheme: :attention, size: :medium)) { "Backordered" }
      else
        render(Primer::Beta::Label.new(scheme: :danger, size: :medium)) { "Backordered, no inbound!" }
      end
    else
      render(Primer::Beta::Label.new(scheme: :secondary, size: :medium)) { "No inventory" }
    end
  end

  def render_sku_actions(sku)
    render Primer::Alpha::ActionMenu.new do |menu|
      menu.with_show_button(icon: :"kebab-horizontal", "aria-label": "Actions", scheme: :invisible)

      menu.with_item(label: "View details", href: warehouse_sku_path(sku)) do |item|
        item.with_leading_visual_icon(icon: :eye)
      end

      if sku.zenventory_url.present?
        menu.with_item(label: "Open in Zenventory", href: sku.zenventory_url, content_arguments: { target: "_blank" }) do |item|
          item.with_leading_visual_icon(icon: :"link-external")
        end
      end

      if current_user&.is_admin?
        menu.with_item(label: "Edit", href: edit_admin_warehouse_sku_path(sku)) do |item|
          item.with_leading_visual_icon(icon: :pencil)
        end
      end
    end
  end

  def category_icon(category)
    {
      "sticker" => :"note",
      "poster" => :"image",
      "card" => :"credit-card",
      "flyer" => :"file",
      "other_printed_material" => :file,
      "hardware" => :"cpu",
      "book" => :"book",
      "swag" => :"gift",
      "grant" => :"mortar-board",
      "prize" => :"trophy"
    }[category.to_s] || :archive
  end
end
