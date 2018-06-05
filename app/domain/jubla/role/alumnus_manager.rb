module Jubla::Role
  class AlumnusManager

    attr_reader :role, :group, :person

    def initialize(role)
      @role = role
      @group = role.group
      @person = role.person
    end

    def create_alumnus_role
      if last_role_for_person_in_group?
        role = group.alumnus_class.new(person: person, group: group)
        role.label = role.class.label
        role.save!
      end
    end

    def destroy_alumnus_role
    end

    def create_alumnus_member
      return unless applies?
      alumnus_member = create_member_role

      if alumnus_member
        update_contactable_flags
        enqueue_mail_job if person.email.present?
      end
    end

    def destroy_alumnus_member
      update_contactable_flags
      alumnus_member_roles_in_layer.where.not(roles: { id: role.id }).destroy_all
    end

    private

    def applies?
      role.active_roles_in_layer.empty? && !group.alumnus? && person_old_enough?
    end

    def person_old_enough?
      return true unless is_a?(Group::ChildGroup::Child)
      return false unless person.years
      min_age_for_alumni_member <= person.years
    end

    def min_age_for_alumni_member
      @min_age_for_alumni_member ||=
        Settings.alumni_administrations.min_age_for_alumni_member
    end

    def create_member_role
      member = group.alumnus_member_class.new(person: person, group: group.alumnus_group)
      member.save
    end

    def enqueue_mail_job
      AlumniMailJob.new(group.alumnus_group.id, role.person.id).enqueue!(run_at: 1.day.from_now)
    end

    def update_contactable_flags
      person.update(contactable_by_federation: true,
                    contactable_by_state: true,
                    contactable_by_region: true,
                    contactable_by_flock: true)
    end

    def alumnus_member_roles_in_layer
      person.roles.joins(:group)
        .where(roles:  { type: alumnus_member_role_types },
               groups: { layer_group_id: group.layer_group_id })
    end

    def alumnus_member_role_types
      Group::AlumnusGroup::Member.subclasses.collect(&:sti_name)
    end

    def last_role_for_person_in_group?
      group.roles.where(person_id: person.id).empty?
    end


  end
end
