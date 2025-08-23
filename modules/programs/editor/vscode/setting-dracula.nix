# /home/player00/NixOS/modules/programs/editor/vscode/settings-dracula.nix
{
  lib,
  pkgs,
  ...
}: {
  programs.vscode.profiles.default.userSettings = {
    "editor.fontSize" = 14;
    "editor.fontFamily" = "'JetBrainsMono Nerd Font', 'SymbolsNerdFont', 'monospace', monospace";
    "editor.fontLigatures" = true;
    "editor.formatOnSave" = true;
    "editor.formatOnPaste" = true;
    "editor.formatOnType" = false;
    "editor.inlineSuggest.enabled" = true;
    "editor.semanticHighlighting.enabled" = true;
    "editor.renderControlCharacters" = false;
    "editor.scrollbar.horizontal" = "hidden";
    "editor.scrollbar.horizontalScrollbarSize" = 2;
    "editor.scrollbar.vertical" = "hidden";
    "editor.scrollbar.verticalScrollbarSize" = 2;
    "editor.mouseWheelZoom" = true;
    "editor.minimap.enabled" = false;
    "editor.codeActionsOnSave" = {"source.organizeImports" = "explicit";};

    "workbench.colorTheme" = "Dracula";
    "workbench.iconTheme" = "vscode-icons";
    "workbench.sideBar.location" = "left";
    "workbench.layoutControl.type" = "menu";
    "workbench.editor.limit.enabled" = true;
    "workbench.editor.limit.value" = 10;
    "workbench.editor.limit.perEditorGroup" = true;
    "workbench.startupEditor" = "none";
    "window.titleBarStyle" = "custom";
    "window.menuBarVisibility" = "classic";
    "window.zoomLevel" = 0.5;

    "telemetry.enableCrashReporter" = false;
    "telemetry.enableTelemetry" = false;
    "security.workspace.trust.untrustedFiles" = "open";

    "git.enableSmartCommit" = true;
    "git.autofetch" = true;
    "git.confirmSync" = false;
    "gitlens.hovers.annotations.changes" = false;
    "gitlens.hovers.avatars" = false;

    "C_Cpp.autocompleteAddParentheses" = true;
    "C_Cpp.formatting" = "vcFormat";
    "C_Cpp.vcFormat.newLine.closeBraceSameLine.emptyFunction" = true;
    "C_Cpp.vcFormat.newLine.closeBraceSameLine.emptyType" = true;
    "C_Cpp.vcFormat.space.beforeEmptySquareBrackets" = true;
    "C_Cpp.vcFormat.space.betweenEmptyBraces" = true;
    "C_Cpp.vcFormat.space.betweenEmptyLambdaBrackets" = true;
    "C_Cpp.vcFormat.newLine.beforeOpenBrace.block" = "sameLine";
    "C_Cpp.vcFormat.newLine.beforeOpenBrace.function" = "sameLine";
    "C_Cpp.vcFormat.newLine.beforeElse" = false;
    "C_Cpp.vcFormat.newLine.beforeCatch" = false;
    "C_Cpp.vcFormat.newLine.beforeOpenBrace.type" = "sameLine";
    "C_Cpp.vcFormat.indent.caseLabels" = true;
    "C_Cpp.intelliSenseCacheSize" = 2048;
    "C_Cpp.intelliSenseMemoryLimit" = 2048;
    "C_Cpp.default.browse.path" = ["${workspaceFolder}/**"];
    "C_Cpp.default.cStandard" = "gnu11";
    "C_Cpp.inlayHints.parameterNames.hideLeadingUnderscores" = false;
    "C_Cpp.intelliSenseUpdateDelay" = 500;
    "C_Cpp.workspaceParsingPriority" = "medium";
    "C_Cpp.clang_format_sortIncludes" = true;
    "C_Cpp.doxygen.generatedStyle" = "/**";

    "vim.leader" = "<Space>";
    "vim.useCtrlKeys" = true;
    "vim.hlsearch" = true;
    "vim.useSystemClipboard" = true;
    "vim.handleKeys" = {
      "<C-f>" = true;
      "<C-a>" = false;
    };
    "vim.insertModeKeyBindings" = [
      {
        before = ["k" "j"];
        after = ["<Esc>" "l"];
      }
    ];

    "vim.normalModeKeyBindingsNonRecursive" = [
      {
        before = ["<S-h>"];
        commands = [":bprevious"];
      }
      {
        before = ["<S-l>"];
        commands = [":bnext"];
      }
      {
        before = ["leader" "v"];
        commands = [":vsplit"];
      }
      {
        before = ["leader" "s"];
        commands = [":split"];
      }
      {
        before = ["<C-h>"];
        commands = ["workbench.action.focusLeftGroup"];
      }
      {
        before = ["<C-j>"];
        commands = ["workbench.action.focusBelowGroup"];
      }
      {
        before = ["<C-k>"];
        commands = ["workbench.action.focusAboveGroup"];
      }
      {
        before = ["<C-l>"];
        commands = ["workbench.action.focusRightGroup"];
      }
      {
        before = ["leader" "w"];
        commands = [":w!"];
      }
      {
        before = ["leader" "q"];
        commands = [":q!"];
      }
      {
        before = ["leader" "x"];
        commands = [":x!"];
      }
      {
        before = ["[" "d"];
        commands = ["editor.action.marker.prev"];
      }
      {
        before = ["];" "d"];
        commands = ["editor.action.marker.next"];
      }
      {
        before = ["<leader>" "c" "a"];
        commands = ["editor.action.quickFix"];
      }
      {
        before = ["<leader>" "f"];
        commands = ["workbench.action.quickOpen"];
      }
      {
        before = ["<C-n>"];
        commands = ["editor.action.toggleSidebarVisibility"];
      }
      {
        before = ["<leader>" "p"];
        commands = ["editor.action.formatDocument"];
      }
      {
        before = ["g" "h"];
        commands = ["editor.action.showDefinitionPreviewHover"];
      }
    ];

    "vim.visualModeKeyBindings" = [
      {
        before = ["<"];
        commands = ["editor.action.outdentLines"];
      }
      {
        before = [">"];
        commands = ["editor.action.indentLines"];
      }
      {
        before = ["J"];
        commands = ["editor.action.moveLinesDownAction"];
      }
      {
        before = ["K"];
        commands = ["editor.action.moveLinesUpAction"];
      }
      {
        before = ["leader" "c"];
        commands = ["editor.action.commentLine"];
      }
    ];
  };
}
