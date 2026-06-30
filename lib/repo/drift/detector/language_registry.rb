# frozen_string_literal: true

module Repo
  module Drift
    module Detector
      class LanguageRegistry
        LANGUAGE_BY_EXTENSION = {
          '.rb' => 'Ruby',
          '.rake' => 'Ruby',
          '.py' => 'Python',
          '.js' => 'JavaScript',
          '.jsx' => 'JavaScript',
          '.ts' => 'TypeScript',
          '.tsx' => 'TypeScript',
          '.java' => 'Java',
          '.kt' => 'Kotlin',
          '.go' => 'Go',
          '.rs' => 'Rust',
          '.php' => 'PHP',
          '.cs' => 'C#',
          '.c' => 'C',
          '.h' => 'C/C++',
          '.cc' => 'C++',
          '.cpp' => 'C++',
          '.swift' => 'Swift',
          '.scala' => 'Scala',
          '.ex' => 'Elixir',
          '.exs' => 'Elixir',
          '.sh' => 'Shell',
          '.bash' => 'Shell',
          '.zsh' => 'Shell',
          '.sql' => 'SQL'
        }.freeze

        module_function

        def detect(path)
          extension = File.extname(path.to_s)
          LANGUAGE_BY_EXTENSION.fetch(extension, 'unknown')
        end
      end
    end
  end
end
