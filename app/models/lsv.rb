module LSV
    SLUGS = {
      msr: MarketingShipmentRequest,
      hs: HighSeasShipment,
      boba: BobaDropsShipment,
      oo: OneOffShipment,
      pf: PrintfulShipment
    }

    INVERSE = SLUGS.invert.freeze

    def self.slug_for(lsv)
        s = INVERSE[lsv.class.responsible_class]
    end

    TYPES = SLUGS.values.freeze
end