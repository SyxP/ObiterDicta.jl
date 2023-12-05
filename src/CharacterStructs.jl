struct Personality
    id :: Int
end

struct PersonalityFilter
    fn :: Function # returns true if passed Filter
    description :: String # printed while Filter is applied
end

struct EGO
    id :: Int
end

struct EGOVoice
end

struct EGOFilter
    fn :: Function # return true if passed Filter
    description :: String # printed while Filter is applied
end