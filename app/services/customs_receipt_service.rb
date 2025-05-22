module CustomsReceiptService
  class CustomsReceiptable < Literal::Data
    prop :order_number, String
    prop :tracking_number, String, optional: true
    prop :not_gifted, Boolean, default: false
    prop :additional_info, String, optional: true
    prop :contents, Array, of: CustomsReceiptService::CustomsReceiptItem
    prop :shipping_cost, Float, optional: true
  end

  class CustomsReceiptItem < Literal::Data
    prop :name, String
    prop :quantity, Integer
    prop :value, Float
  end

  class CustomsReceiptTemplate < Phlex::HTML
    def initialize(receiptable)
      @r = receiptable
    end

    def view_template
      doctype :html
      html do
        head do
          meta charset: "UTF-8"
          style <<~CSS
                  body {
                      padding: 16px;
                      color: black;
                      font-family: sans-serif;
                  }
                  h4 {
                      font-weight: 400
                  }
                  .table {
                      display: grid;
                      grid-template-columns: 1fr auto auto;
                      width: 100%
                  }
                  .table > .header {
                      display: contents;
                  }
                  .table .cell {
                    padding: .5px 8px
                  }
                  .table > .header > .cell {
                      background: #000;
                      color: #fff;
                      font-weight: 400;
                      text-align: left;
                  }
                  .table > .row {
                      display: contents;
                  }
                  .table > .row:nth-child(odd) *
                  {
                      background-color: #ececec
                  ;
                  }
                  td {
                      border: none;
                  }
                  img.emoji {
                      height: 1em;
                      width: 1em;
                      margin: 0 .05em 0 .1em;
                      vertical-align: -0.1em;
                  }
                CSS
          title { "Customs Receipt – #{@r.order_number}" }
        end
        body do
          img height: 72, style: "display:inline-block; float: left;", src: "data:image/png;base64,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"
          div style: "display: inline-block; padding-left: 10px" do
            b { "Hack Club" }
            br
            text "15 Falls Rd "
            br
            text "Shelburne, VT 05482 "
            br
            text "United States"
          end
          br
          br
          br
          b { "Shipment ID:" }
          text " #"
          text @r.order_number
          br
          br
        end
      end
    end
  end
end
