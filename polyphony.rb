# load all files
[
  "composition",
  "ensembles",
  "ideation",
  "logging",
  "performance-helpers",
  "performance-midi",
  "performance-spi",
  "performance",
  "rhythm",
  "space",
  "state",
  "tests",
  "timekeeping",
  "transition",
  "utils",
  # load settings last
  "settings"
].each do |filename|
  load(File.expand_path("#{filename}.rb", -File.dirname(__FILE__)))
end

#
# *Ideate. Compose. Perform.*
#
module Polyphony
  #
  # Main methods.
  #
  module Core
    extend self
    include Polyphony::Composition
    include Polyphony::Instruments
    include Polyphony::Ideation
    include Polyphony::Logging
    include Polyphony::Performance::Helpers
    include Polyphony::Performance::Midi
    include Polyphony::Performance::SPi
    include Polyphony::Performance
    include Polyphony::Rhythm
    include Polyphony::Settings
    include Polyphony::Space
    include Polyphony::State
    include Polyphony::Timekeeping
    include Polyphony::Transition
    include Polyphony::Tests
    include Polyphony::Utils
    include SonicPi::Lang::Core
    include SonicPi::Lang::Midi
    include SonicPi::Lang::Sound

    #
    # Prepares Sonic Pi.
    #
    def init
      initEnv()
      initMIDI()
      initTimeState()
      initState()
      initVoices()
    end

    #
    # Prepares Sonic Pi environment.
    #
    def initEnv
      use_bpm(Settings::TIMEKEEPING[:unitsPerMinute])

      use_random_seed(Settings::RANDOM[:seed])

      use_cue_logging(Settings::LOGGING[:shouldLogCues])
      use_debug(Settings::LOGGING[:shouldLogDebug])
      use_midi_logging(Settings::LOGGING[:shouldLogMIDI])
    end

    #
    # Prepares Sonic Pi time-state.
    #
    def initTimeState
      set(-"numMeasuresSinceTransition", 0)
      set(-"numTransitionMeasureDivisions", nil)

      set(-"space/chordRoot", 0)
      set(-"space/key", Settings::SPACE[:initialKey])

      set(-"time/unitsElapsed", 0)
    end

    #
    # Starts all live loops.
    #
    def run
      init()

      live_loop :maintainLog, sync_bpm: -"time/measure" do
        activateLogging()
        sync_bpm(-"time/measure")
      end

      live_loop :maintainSpace, delay: (Settings::SPACE[:numMeasuresInitialDelay] * Settings::TIMEKEEPING[:numUnitsPerMeasure]), sync_bpm: -"time/measure" do
        waitNumUnitsQuantised(Settings::TIMEKEEPING[:numUnitsPerMeasure] / 2)
        activateSpace()
        sync_bpm(-"time/measure")
      end

      live_loop :maintainState, delay: (Settings::STATE[:numMeasuresInitialDelay] * Settings::TIMEKEEPING[:numUnitsPerMeasure]), sync_bpm: -"time/measure" do
        waitNumUnitsQuantised(Settings::TIMEKEEPING[:numUnitsPerMeasure] / 2)
        activateState()
        sync_bpm(-"time/measure")
      end

      live_loop :maintainTimekeeper do
        activateTimekeeping()
      end

      live_loop :maintainTransition, sync_bpm: -"time/measure" do
        activateTransition()
        sync_bpm(-"time/measure")
      end

      live_loop :maintainVoices, sync_bpm: -"time/measure" do
        Settings::VOICES[:selection].each do |voiceType|
          in_thread name: "#{voiceType}".to_sym do
            activateVoices(voiceType)
          end
        end
        sync_bpm(-"time/measure")
      end
    end
  end
end

include Polyphony::Core
