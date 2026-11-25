module LSV
  SLUGS = {
    msr: MarketingShipmentRequest,
    hs: HighSeasShipment,
    boba: BobaDropsShipment,
    oo: OneOffShipment,
    pf: PrintfulShipment
  }

  def self.slug_for(lsv) = lsv.class.slug

  TYPES = SLUGS.values.freeze
end
