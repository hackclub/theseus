# SnailMail Label Generation

This module provides functionality for generating shipping labels and envelope templates for letters and packages.

## Template Sizes

The system supports multiple template sizes:

- `:standard` - 4x6 inch labels (default)
- `:envelope` - #10 business envelopes (9.5" x 4.125")

## Adding a New Template

Creating a new template is simple:

1. Create a new file in `app/snail_mail/templates/` with a name like `your_template_name_template.rb`
2. Extend either `BaseTemplate` or one of the existing templates
3. Define the template metadata and render method

### Example Template

```ruby
require_relative '../base_template'

module SnailMail
  module Templates
    class MyAwesomeTemplate < SnailMail::BaseTemplate
      # Template metadata
      def self.template_name
        "my_awesome"  # Will be used to select this template
      end
      
      def self.template_size
        :standard  # Use standard 4x6 size (or :envelope for #10 envelopes)
      end
      
      def self.template_description
        "My awesome new template"
      end

      # Template rendering logic
      def render(pdf, letter)
        # Add your rendering code here
        
        # Example:
        render_return_address(pdf, letter, 10, 270, 130, 70)
        render_destination_address(pdf, letter, 105, 175, 250, 100)
        render_imb(pdf, letter, 100, 90, 280, 30)
        render_qr_code(pdf, letter, 10, 180, 75)
      end
    end
  end
end
```

### Available Helper Methods

Base templates provide these helper methods:

- `render_return_address(pdf, letter, x, y, width, height, options = {})`
- `render_destination_address(pdf, letter, x, y, width, height, options = {})`
- `render_imb(pdf, letter, x, y, width, height, options = {})`
- `render_qr_code(pdf, letter, x, y, size = 80)`
- `image_path(image_name)` - Get path to an image in the assets folder
- `render_text_box(pdf, text, x, y, width, height, options = {})` - Generic text box renderer

### Character-Based Templates

To create a character-based template (with a character and speech bubble):

```ruby
require_relative 'character_template'

module SnailMail
  module Templates
    class MyCharacterTemplate < SnailMail::Templates::CharacterTemplate
      def self.template_name
        "my_character"
      end
      
      def self.template_description
        "My custom character template"
      end

      def initialize(options = {})
        super(options.merge(
          character_image: 'my-character.png',  # Image in assets/images folder
          character_position: { x: 10, y: 100, width: 120 },
          speech_position: { x: 100, y: 250, width: 300, height: 100 }
        ))
      end
      
      # Add any custom rendering logic by overriding render
    end
  end
end
```

## Using Templates

Templates can be used from the UI by selecting them in the dropdown when viewing a letter.

### Basic Usage

```ruby
# Generate a label for a letter
SnailMail::Service.generate_label(letter)

# Generate labels for a batch of letters
SnailMail::Service.generate_batch_labels(letters)
```

### Specifying Templates

Specify a template when generating a label:

```ruby
# Pass template directly in the options
SnailMail::Service.generate_label(letter, template: "my_awesome")
```

For backward compatibility, the system will still check `letter.rubber_stamps['template']` if no template is specified in the options.

### Template Cycling

For batch processing, you can cycle through multiple templates:

```ruby
# Cycle through 3 different templates for a batch of letters
template_cycle = ["standard", "character", "fancy"]
SnailMail::Service.generate_batch_labels(letters, template_cycle: template_cycle)
```

This will assign templates to letters in a round-robin fashion, creating separate PDF files for each template size group.

## Template Management

```ruby
# List all available templates
SnailMail::Service.available_templates

# Get template information
SnailMail::Service.template_info

# Get templates for a specific size
SnailMail::Service.templates_for_size(:standard)

# Set the default template
SnailMail::Service.set_default_template("standard")
```

## Controller Usage

In your controllers, pass the template as an option:

```ruby
# In LettersController
def generate_label
  letter = Letter.find(params[:id])
  template = params[:template] || "standard"
  
  SnailMail::Service.generate_label(letter, template: template)
end

# In BatchesController
def generate_batch_labels
  batch = Batch.find(params[:id])
  template_cycle = params[:template_cycle] || ["standard"]
  
  SnailMail::Service.generate_batch_labels(batch.letters, template_cycle: template_cycle)
end
``` 