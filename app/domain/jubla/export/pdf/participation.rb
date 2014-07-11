# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Jubla::Export::Pdf
  module Participation
    class PersonAndEvent < Export::Pdf::Participation::PersonAndEvent

      private

      def person_attributes
        super + [:j_s_number]
      end
    end
    class EventDetails < Export::Pdf::Participation::EventDetails
      def render
        super
        render_condition if condition?
      end

      private

      def render_condition
        with_count(Event::Course::Condition.model_name.human) do
          text event.condition.content
        end
      end

      def condition?
        course? && event.condition.present?
      end
    end

    class Header < Export::Pdf::Participation::Header
      def image_path
        Wagons.find('jubla').root.join('app/assets/images/logo_jubla.png')
      end
    end

    class Confirmation <  Export::Pdf::Participation::Confirmation

      def render_heading
        super
        render_signature if event.signature?
        render_signature_confirmation if signature_confirmation?
      end

      private

      def render_signature_confirmation
        render_signature(event.signature_confirmation_text)
      end

      def render_signature(header = Event::Role::Participant.model_name.human)
        y = cursor
        render_boxed(-> { text header; label_with_dots(date_and_location) },
                     -> { move_down_line; label_with_dots(t('.signature')) })
        move_down_line
      end

      def signature_confirmation?
        event.signature_confirmation? && event.signature_confirmation_text?
      end

      def date_and_location
        [Event::Date.model_name.human,
         Event::Date.human_attribute_name(:location)].join(' / ')
      end
    end


    class Runner < Export::Pdf::Participation::Runner
      Export::Pdf::Participation::Runner.stroke_bounds = true

      def sections
        [Header,
         PersonAndEvent,
         Export::Pdf::Participation::Specifics,
         Confirmation,
         EventDetails]
      end
    end

  end
end
