# Letter::InstantQueue is STI on Letter::Queue, and Pundit resolves policies from
# the record's own class, so the subclass needs a policy constant of its own or
# every `authorize @letter_queue` raises Pundit::NotDefinedError.
#
# Permissions are identical to a regular queue: owner-or-admin for show/edit/
# update, any signed-in user for new/create, admin-only for destroy.
class Letter::InstantQueuePolicy < Letter::QueuePolicy
end
