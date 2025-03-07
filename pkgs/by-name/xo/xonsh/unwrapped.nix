{
  lib,
  coreutils,
  fetchFromGitHub,
  git,
  gitUpdater,
  glibcLocales,
  pythonPackages,
}:

let

  argset = {
    pname = "xonsh";
    version = "0.19.0";
    pyproject = true;

    # PyPI package ships incomplete tests
    src = fetchFromGitHub {
      owner = "xonsh";
      repo = "xonsh";
      rev = "refs/tags/${argset.version}";
      hash = "sha256-rt402MKnhjC/AYz9Rm6B5RkivcVxveVW2rM/nT/xcNo=";
    };

    nativeBuildInputs = with pythonPackages; [
      setuptools
      wheel
    ];

    propagatedBuildInputs = (
      with pythonPackages;
      [
        ply
        prompt-toolkit
        pygments
      ]
    );

    nativeCheckInputs =
      [
        git
        glibcLocales
      ]
      ++ (with pythonPackages; [
        pip
        pyte
        pytest-mock
        pytest-subprocess
        pytestCheckHook
        requests
      ]);

    disabledTests = [
      # fails on sandbox
      "test_colorize_file"
      "test_loading_correctly"
      "test_no_command_path_completion"
      "test_bsd_man_page_completions"
      "test_xonsh_activator"

      # fails on non-interactive shells
      "test_capture_always"
      "test_casting"
      "test_command_pipeline_capture"
      "test_dirty_working_directory"
      "test_man_completion"
      "test_vc_get_branch"
      "test_bash_and_is_alias_is_only_functional_alias"

      # flaky tests
      "test_script"
      "test_alias_stability"
      "test_alias_stability_exception"
      "test_complete_import"
      "test_subproc_output_format"

      # https://github.com/xonsh/xonsh/issues/5569
      "test_spec_decorator_alias_output_format"
    ];

    disabledTestPaths = [
      # fails on sandbox
      "tests/completers/test_command_completers.py"
      "tests/shell/test_ptk_highlight.py"
      # fails on non-interactive shells
      "tests/prompt/test_gitstatus.py"
      "tests/completers/test_bash_completer.py"
    ];

    # https://github.com/NixOS/nixpkgs/issues/248978
    dontWrapPythonPrograms = true;

    env.LC_ALL = "en_US.UTF-8";

    postPatch = ''
      sed -ie 's|/bin/ls|${lib.getExe' coreutils "ls"}|' tests/test_execer.py
      sed -ie 's|SHELL=xonsh|SHELL=$out/bin/xonsh|' tests/test_integrations.py

      for script in tests/test_integrations.py scripts/xon.sh $(find -name "*.xsh"); do
        sed -ie 's|/usr/bin/env|${lib.getExe' coreutils "env"}|' $script
      done
      patchShebangs .
    '';

    preCheck = ''
      export HOME=$TMPDIR
      export PATH=$out/bin:$PATH
    '';

    passthru = {
      shellPath = "/bin/xonsh";
      python = pythonPackages.python; # To the wrapper
      wrapper = throw "The top-level xonsh package is now wrapped. Use it directly.";
      updateScript = gitUpdater { };
    };

    meta = {
      homepage = "https://xon.sh/";
      description = "Python-ish, BASHwards-compatible shell";
      changelog = "https://github.com/xonsh/xonsh/raw/main/CHANGELOG.rst";
      license = with lib.licenses; [ bsd3 ];
      mainProgram = "xonsh";
      maintainers = with lib.maintainers; [ samlukeyes123 ];
    };
  };
in
pythonPackages.buildPythonPackage argset
