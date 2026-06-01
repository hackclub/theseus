export const REQUIRED_FIELDS = [
  'first_name',
  'line_1',
  'city',
  'state',
  'postal_code',
  'country',
];

// Human-readable labels for address fields
export const FIELD_LABELS = {
  first_name: 'First Name',
  last_name: 'Last Name',
  line_1: 'Address Line 1',
  line_2: 'Address Line 2',
  city: 'City',
  state: 'State / Province',
  postal_code: 'ZIP / Postal Code',
  country: 'Country',
  phone_number: 'Phone Number',
  email: 'Email',
  rubber_stamps: 'Rubber Stamps',
};

// Default mapping heuristics: lowercase CSV header -> address field
// Order matters — first match wins when multiple headers could map to the same field
export const DEFAULT_MAPPING = {
  // direct / common
  'email': 'email',
  'first name': 'first_name',
  'last name': 'last_name',
  'firstname': 'first_name',
  'lastname': 'last_name',
  'first_name': 'first_name',
  'last_name': 'last_name',
  'line 1': 'line_1',
  'line 2': 'line_2',
  'line_1': 'line_1',
  'line_2': 'line_2',
  'address': 'line_1',
  'address1': 'line_1',
  'address2': 'line_2',
  'city': 'city',
  'state': 'state',
  'zip': 'postal_code',
  'zipcode': 'postal_code',
  'zip code': 'postal_code',
  'postal_code': 'postal_code',
  'postal code': 'postal_code',
  'country': 'country',
  'phone': 'phone_number',
  'phone_number': 'phone_number',
  'phone number': 'phone_number',
  'rubber_stamps': 'rubber_stamps',
  'rubber stamps': 'rubber_stamps',

  // loops format
  'addressline1': 'line_1',
  'addressline2': 'line_2',
  'addresscity': 'city',
  'addressstate': 'state',
  'addresszipcode': 'postal_code',
  'addresszip': 'postal_code',
  'addresscountry': 'country',

  // hcb promotions format
  'address (zip/postal code)': 'postal_code',
  'address (city)': 'city',
  'address (state/province)': 'state',
  'address (country)': 'country',
  'address (line 1)': 'line_1',
  'address (line 2)': 'line_2',
  'recipient name': 'first_name',
  'login email': 'email',

  // YSWS unified DB format
  'state / province': 'state',
  'zip / postal code': 'postal_code',
  'state/province': 'state',
  'zip/postal code': 'postal_code',
};
