# WARNING - This really only works for development or single-instance deployments
class InMemorySessionStore
  def self.find(id)
    repo[id]
  end

  def self.store(session)
    id = SecureRandom.uuid
    repo[id] = session
    id
  end

  def self.clear
    @@repo = nil
  end

  def self.repo
    @@repo ||= {}
  end
end
