# Be sure to restart your server when you modify this file.

# Add new inflection rules using the following format. Inflections
# are locale specific, and you may define rules for as many different
# locales as you wish. All of these examples are active by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.plural /^(ox)$/i, "\\1en"
#   inflect.singular /^(ox)en/i, "\\1"
#   inflect.irregular "person", "people"
#   inflect.uncountable %w( fish sheep )
# end

# These inflection rules are supported but not enabled by default:
ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.acronym "USPS"
  inflect.acronym "API"
  inflect.irregular "indicium", "indicia"
  inflect.acronym "EasyPost"
  inflect.acronym "SKU"
  inflect.acronym "SKUs"
  inflect.acronym "IMb"
  inflect.acronym "QR"
  inflect.acronym "HCB"
  inflect.acronym "IV"
  inflect.acronym "MTR"
  inflect.acronym "JSON"
  inflect.acronym "FLIRT"
  inflect.acronym "IMI"
  inflect.acronym "FIM"
  inflect.acronym "EPS"
  inflect.irregular "is", "are"
  inflect.irregular "this", "these"
  inflect.acronym "AI"
  inflect.acronym "LSV"
  inflect.acronym "MSR"
  inflect.acronym "QZ"
  inflect.acronym "OTP"
  inflect.acronym "ETL"
end
