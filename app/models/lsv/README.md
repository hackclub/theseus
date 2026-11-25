# what's lsv?

LSV stands for "legacy Shipment Viewer"!

this subsystem brings packages from Airtable sources previously supported by the now-defunct (but lovely, i'm still very proud of the code...) [Shipment Viewer](https://github.com/hackclub/shipment-viewer) into the public "My Mail" view.

## cool, how?

the job of an LSV [model](./) is to take data from a source (usually an old program Airtable base that's been [tablesync](https://support.airtable.com/articles/2849803278-getting-started-with-airtable-sync)ed into the [Shipment Viewer - PROD](https://airtable.com/appfymsBOQvDUVDrn/tblXAOmUfnIA16Tmd/) base) and coerce it into, at minimum:
```ruby
{
  id:,
  date:,
  tracking_link:,
  tracking_number:,
  type: self.class.name,
  type_text:,
  title: title_text,
  shipped: shipped?,
  icon:,
  description:,
  source_record: source_url
}
```
these power the API.
additionally, if a shipment type has something fancier to show unique to it, it can define a custom [LSV type view](../views/public/lsv/type) that pulls additional data off the record to show in the UI!

solid chance we never touch this again, but it's nice to have old program data here ^_^
