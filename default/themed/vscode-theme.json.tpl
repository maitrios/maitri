{
    "name": "maitri",
    "$schema": "vscode://schemas/color-theme",
    "type": "{{ theme_type }}",
    "semanticHighlighting": true,
    "semanticTokenColors": {
        "parameter": {
            "foreground": "{{ orange }}",
            "italic": true
        },
        "variable": "{{ foreground }}",
        "variable.readonly": "{{ blue }}",
        "variable.defaultLibrary": {
            "foreground": "{{ blue }}",
            "italic": true
        },
        "property": "{{ orange }}",
        "property.readonly": "{{ orange }}",
        "function": "{{ green }}",
        "function.defaultLibrary": "{{ cyan }}",
        "method": "{{ green }}",
        "method.defaultLibrary": "{{ cyan }}",
        "class": "{{ cyan }}",
        "class.defaultLibrary": {
            "foreground": "{{ cyan }}",
            "italic": true
        },
        "interface": {
            "foreground": "{{ cyan }}",
            "italic": true
        },
        "struct": "{{ cyan }}",
        "enum": "{{ cyan }}",
        "enumMember": "{{ blue }}",
        "type": {
            "foreground": "{{ cyan }}",
            "italic": true
        },
        "typeParameter": {
            "foreground": "{{ magenta }}",
            "italic": true
        },
        "namespace": "{{ cyan }}",
        "macro": "{{ green }}",
        "decorator": {
            "foreground": "{{ green }}",
            "italic": true
        },
        "label": {
            "foreground": "{{ blue }}",
            "italic": true
        },
        "string": "{{ yellow }}",
        "number": "{{ blue }}",
        "boolean": "{{ blue }}",
        "regexp": "{{ red }}",
        "operator": "{{ magenta }}",
        "keyword": "{{ magenta }}",
        "selfKeyword": {
            "foreground": "{{ blue }}",
            "italic": true
        },
        "lifetime": "{{ magenta }}",
        "comment": {
            "foreground": "{{ comment }}",
            "italic": true
        },
        "*.deprecated": {
            "strikethrough": true
        }
    },
    "colors": {
        "foreground": "{{ foreground }}",
        "disabledForeground": "{{ comment }}",
        "descriptionForeground": "{{ comment }}",
        "errorForeground": "{{ red }}",
        "icon.foreground": "{{ light_foreground }}",
        "focusBorder": "{{ border_focus }}",
        "contrastBorder": "#00000000",
        "contrastActiveBorder": "#00000000",
        "widget.border": "{{ border }}",
        "widget.shadow": "#00000040",
        "selection.background": "{{ selection }}",
        "sash.hoverBorder": "{{ border_focus }}",
        "textBlockQuote.background": "{{ dark_background }}",
        "textBlockQuote.border": "{{ border }}",
        "textCodeBlock.background": "{{ dark_background }}",
        "textLink.foreground": "{{ link }}",
        "textLink.activeForeground": "{{ link }}",
        "textPreformat.foreground": "{{ cyan }}",
        "textPreformat.background": "{{ dark_background }}",
        "textSeparator.foreground": "{{ border }}",
        "toolbar.hoverBackground": "{{ mix background foreground 6% }}",
        "toolbar.activeBackground": "{{ mix background accent 8% }}",
        "button.background": "{{ accent }}",
        "button.foreground": "{{ background }}",
        "button.hoverBackground": "{{ mix accent foreground 13% }}",
        "button.border": "#00000000",
        "button.separator": "{{ background }}66",
        "button.secondaryBackground": "{{ lighter_background }}",
        "button.secondaryForeground": "{{ foreground }}",
        "button.secondaryHoverBackground": "{{ mix lighter_background foreground 8% }}",
        "checkbox.background": "{{ background }}",
        "checkbox.foreground": "{{ foreground }}",
        "checkbox.border": "{{ border }}",
        "checkbox.selectBackground": "{{ background }}",
        "checkbox.selectBorder": "{{ border_focus }}",
        "dropdown.background": "{{ background }}",
        "dropdown.listBackground": "{{ dark_background }}",
        "dropdown.border": "{{ border }}",
        "dropdown.foreground": "{{ foreground }}",
        "input.background": "{{ background }}",
        "input.border": "{{ border }}",
        "input.foreground": "{{ foreground }}",
        "input.placeholderForeground": "{{ comment }}",
        "inputOption.activeBackground": "{{ mix background accent 16% }}",
        "inputOption.activeBorder": "{{ border_focus }}",
        "inputOption.activeForeground": "{{ bright_foreground }}",
        "inputOption.hoverBackground": "{{ mix background foreground 6% }}",
        "inputValidation.errorBackground": "{{ dark_background }}",
        "inputValidation.errorForeground": "{{ red }}",
        "inputValidation.errorBorder": "{{ red }}",
        "inputValidation.infoBackground": "{{ dark_background }}",
        "inputValidation.infoForeground": "{{ cyan }}",
        "inputValidation.infoBorder": "{{ cyan }}",
        "inputValidation.warningBackground": "{{ dark_background }}",
        "inputValidation.warningForeground": "{{ orange }}",
        "inputValidation.warningBorder": "{{ orange }}",
        "scrollbar.shadow": "#00000040",
        "scrollbarSlider.background": "{{ muted }}cc",
        "scrollbarSlider.hoverBackground": "{{ border }}cc",
        "scrollbarSlider.activeBackground": "{{ border_focus }}cc",
        "badge.background": "{{ accent }}",
        "badge.foreground": "{{ background }}",
        "progressBar.background": "{{ accent }}",
        "list.activeSelectionBackground": "{{ mix background accent 16% }}",
        "list.activeSelectionForeground": "{{ bright_foreground }}",
        "list.activeSelectionIconForeground": "{{ bright_foreground }}",
        "list.inactiveSelectionBackground": "{{ mix background accent 8% }}",
        "list.inactiveSelectionForeground": "{{ foreground }}",
        "list.inactiveSelectionIconForeground": "{{ foreground }}",
        "list.focusBackground": "{{ mix background accent 16% }}",
        "list.focusForeground": "{{ bright_foreground }}",
        "list.focusOutline": "{{ border_focus }}",
        "list.focusAndSelectionOutline": "{{ border_focus }}",
        "list.inactiveFocusBackground": "{{ mix background accent 8% }}",
        "list.inactiveFocusOutline": "{{ border }}",
        "list.hoverBackground": "{{ mix background foreground 6% }}",
        "list.hoverForeground": "{{ foreground }}",
        "list.dropBackground": "{{ mix background accent 8% }}",
        "list.dropBetweenBackground": "{{ border_focus }}",
        "list.highlightForeground": "{{ accent }}",
        "list.focusHighlightForeground": "{{ accent }}",
        "list.invalidItemForeground": "{{ red }}",
        "list.errorForeground": "{{ red }}",
        "list.warningForeground": "{{ orange }}",
        "list.deemphasizedForeground": "{{ comment }}",
        "list.filterMatchBackground": "{{ mix background accent 16% }}",
        "list.filterMatchBorder": "{{ border_focus }}",
        "listFilterWidget.background": "{{ dark_background }}",
        "listFilterWidget.outline": "{{ border_focus }}",
        "listFilterWidget.noMatchesOutline": "{{ red }}",
        "listFilterWidget.shadow": "#00000040",
        "tree.indentGuidesStroke": "{{ border }}",
        "tree.inactiveIndentGuidesStroke": "{{ muted }}",
        "tree.tableColumnsBorder": "{{ border }}",
        "tree.tableOddRowsBackground": "{{ mix background foreground 6% }}",
        "activityBar.background": "{{ dark_background }}",
        "activityBar.foreground": "{{ bright_foreground }}",
        "activityBar.inactiveForeground": "{{ comment }}",
        "activityBar.border": "{{ border }}",
        "activityBar.activeBorder": "{{ accent }}",
        "activityBar.activeBackground": "#00000000",
        "activityBar.activeFocusBorder": "{{ border_focus }}",
        "activityBar.dropBorder": "{{ border_focus }}",
        "activityBarBadge.background": "{{ accent }}",
        "activityBarBadge.foreground": "{{ background }}",
        "activityBarTop.foreground": "{{ bright_foreground }}",
        "activityBarTop.inactiveForeground": "{{ comment }}",
        "activityBarTop.activeBorder": "{{ accent }}",
        "sideBar.background": "{{ dark_background }}",
        "sideBar.foreground": "{{ foreground }}",
        "sideBar.border": "{{ border }}",
        "sideBar.dropBackground": "{{ mix background accent 8% }}",
        "sideBarTitle.foreground": "{{ bright_foreground }}",
        "sideBarSectionHeader.background": "{{ dark_background }}",
        "sideBarSectionHeader.foreground": "{{ bright_foreground }}",
        "sideBarSectionHeader.border": "{{ border }}",
        "sideBarStickyScroll.background": "{{ dark_background }}",
        "sideBarActivityBarTop.border": "{{ border }}",
        "minimap.background": "{{ background }}",
        "minimap.findMatchHighlight": "{{ orange }}",
        "minimap.selectionHighlight": "{{ selection }}",
        "minimap.selectionOccurrenceHighlight": "{{ mix background accent 16% }}",
        "minimap.errorHighlight": "{{ red }}",
        "minimap.warningHighlight": "{{ orange }}",
        "minimap.infoHighlight": "{{ cyan }}",
        "minimapSlider.background": "{{ muted }}80",
        "minimapSlider.hoverBackground": "{{ muted }}cc",
        "minimapSlider.activeBackground": "{{ border }}cc",
        "minimapGutter.addedBackground": "{{ green }}",
        "minimapGutter.modifiedBackground": "{{ blue }}",
        "minimapGutter.deletedBackground": "{{ red }}",
        "editorGroup.border": "{{ border }}",
        "editorGroup.dropBackground": "{{ accent }}33",
        "editorGroup.dropIntoPromptForeground": "{{ foreground }}",
        "editorGroup.dropIntoPromptBackground": "{{ dark_background }}",
        "editorGroup.dropIntoPromptBorder": "{{ border_focus }}",
        "editorGroup.emptyBackground": "{{ background }}",
        "editorGroupHeader.noTabsBackground": "{{ background }}",
        "editorGroupHeader.tabsBackground": "{{ dark_background }}",
        "editorGroupHeader.tabsBorder": "{{ border }}",
        "editorGroupHeader.border": "{{ border }}",
        "tab.activeBackground": "{{ background }}",
        "tab.activeForeground": "{{ bright_foreground }}",
        "tab.activeBorder": "{{ background }}",
        "tab.activeBorderTop": "{{ accent }}",
        "tab.unfocusedActiveBackground": "{{ background }}",
        "tab.unfocusedActiveForeground": "{{ foreground }}",
        "tab.unfocusedActiveBorder": "{{ background }}",
        "tab.unfocusedActiveBorderTop": "{{ border }}",
        "tab.inactiveBackground": "{{ dark_background }}",
        "tab.inactiveForeground": "{{ comment }}",
        "tab.unfocusedInactiveBackground": "{{ dark_background }}",
        "tab.unfocusedInactiveForeground": "{{ comment }}",
        "tab.border": "{{ border }}",
        "tab.hoverBackground": "{{ mix background foreground 6% }}",
        "tab.unfocusedHoverBackground": "{{ mix background foreground 6% }}",
        "tab.hoverForeground": "{{ foreground }}",
        "tab.unfocusedHoverForeground": "{{ foreground }}",
        "tab.hoverBorder": "#00000000",
        "tab.activeModifiedBorder": "{{ blue }}",
        "tab.inactiveModifiedBorder": "{{ blue }}",
        "tab.unfocusedActiveModifiedBorder": "{{ blue }}",
        "tab.unfocusedInactiveModifiedBorder": "{{ blue }}",
        "tab.lastPinnedBorder": "{{ border }}",
        "tab.dragAndDropBorder": "{{ border_focus }}",
        "tab.selectedBackground": "{{ background }}",
        "tab.selectedForeground": "{{ bright_foreground }}",
        "tab.selectedBorderTop": "{{ accent }}",
        "editorPane.background": "{{ background }}",
        "editor.background": "{{ background }}",
        "editor.foreground": "{{ foreground }}",
        "editorLineNumber.foreground": "{{ comment }}",
        "editorLineNumber.activeForeground": "{{ accent }}",
        "editorLineNumber.dimmedForeground": "{{ comment }}",
        "editorCursor.foreground": "{{ bright_foreground }}",
        "editorCursor.background": "{{ background }}",
        "editorMultiCursor.primary.foreground": "{{ bright_foreground }}",
        "editorMultiCursor.secondary.foreground": "{{ light_foreground }}",
        "editor.selectionBackground": "{{ selection }}",
        "editor.inactiveSelectionBackground": "{{ mix background selection 60% }}",
        "editor.selectionHighlightBackground": "{{ accent }}29",
        "editor.selectionHighlightBorder": "#00000000",
        "editor.wordHighlightBackground": "{{ accent }}29",
        "editor.wordHighlightBorder": "#00000000",
        "editor.wordHighlightStrongBackground": "{{ accent }}29",
        "editor.wordHighlightStrongBorder": "{{ border_focus }}",
        "editor.wordHighlightTextBackground": "{{ accent }}29",
        "editor.wordHighlightTextBorder": "#00000000",
        "editor.findMatchBackground": "{{ orange }}66",
        "editor.findMatchForeground": "{{ bright_foreground }}",
        "editor.findMatchBorder": "{{ orange }}",
        "editor.findMatchHighlightBackground": "{{ green }}52",
        "editor.findMatchHighlightBorder": "#00000000",
        "editor.findRangeHighlightBackground": "{{ accent }}1a",
        "editor.findRangeHighlightBorder": "#00000000",
        "searchEditor.findMatchBackground": "{{ green }}52",
        "searchEditor.findMatchBorder": "#00000000",
        "search.resultsInfoForeground": "{{ comment }}",
        "editor.hoverHighlightBackground": "{{ accent }}29",
        "editor.lineHighlightBackground": "{{ lighter_background }}",
        "editor.lineHighlightBorder": "{{ lighter_background }}",
        "editor.rangeHighlightBackground": "{{ accent }}1a",
        "editor.rangeHighlightBorder": "#00000000",
        "editor.symbolHighlightBackground": "{{ accent }}29",
        "editor.symbolHighlightBorder": "#00000000",
        "editor.linkedEditingBackground": "{{ accent }}29",
        "editorLink.activeForeground": "{{ link }}",
        "editorWhitespace.foreground": "{{ mix muted comment 35% }}",
        "editorIndentGuide.background1": "{{ muted }}",
        "editorIndentGuide.background2": "{{ muted }}",
        "editorIndentGuide.background3": "{{ muted }}",
        "editorIndentGuide.background4": "{{ muted }}",
        "editorIndentGuide.background5": "{{ muted }}",
        "editorIndentGuide.background6": "{{ muted }}",
        "editorIndentGuide.activeBackground1": "{{ border }}",
        "editorIndentGuide.activeBackground2": "{{ border }}",
        "editorIndentGuide.activeBackground3": "{{ border }}",
        "editorIndentGuide.activeBackground4": "{{ border }}",
        "editorIndentGuide.activeBackground5": "{{ border }}",
        "editorIndentGuide.activeBackground6": "{{ border }}",
        "editorInlayHint.background": "{{ mix background lighter_background 60% }}",
        "editorInlayHint.foreground": "{{ comment }}",
        "editorInlayHint.typeBackground": "{{ mix background lighter_background 60% }}",
        "editorInlayHint.typeForeground": "{{ comment }}",
        "editorInlayHint.parameterBackground": "{{ mix background lighter_background 60% }}",
        "editorInlayHint.parameterForeground": "{{ comment }}",
        "editorRuler.foreground": "{{ muted }}",
        "editorCodeLens.foreground": "{{ comment }}",
        "editorLightBulb.foreground": "{{ orange }}",
        "editorLightBulbAutoFix.foreground": "{{ green }}",
        "editorLightBulbAi.foreground": "{{ accent }}",
        "editorBracketMatch.background": "{{ mix background accent 16% }}",
        "editorBracketMatch.border": "{{ border_focus }}",
        "editorBracketHighlight.foreground1": "{{ accent }}",
        "editorBracketHighlight.foreground2": "{{ cyan }}",
        "editorBracketHighlight.foreground3": "{{ link }}",
        "editorBracketHighlight.foreground4": "{{ accent }}",
        "editorBracketHighlight.foreground5": "{{ cyan }}",
        "editorBracketHighlight.foreground6": "{{ link }}",
        "editorBracketHighlight.unexpectedBracket.foreground": "{{ red }}",
        "editorBracketPairGuide.activeBackground1": "{{ accent }}",
        "editorBracketPairGuide.activeBackground2": "{{ cyan }}",
        "editorBracketPairGuide.activeBackground3": "{{ link }}",
        "editorBracketPairGuide.activeBackground4": "{{ accent }}",
        "editorBracketPairGuide.activeBackground5": "{{ cyan }}",
        "editorBracketPairGuide.activeBackground6": "{{ link }}",
        "editorBracketPairGuide.background1": "{{ muted }}",
        "editorBracketPairGuide.background2": "{{ muted }}",
        "editorBracketPairGuide.background3": "{{ muted }}",
        "editorBracketPairGuide.background4": "{{ muted }}",
        "editorBracketPairGuide.background5": "{{ muted }}",
        "editorBracketPairGuide.background6": "{{ muted }}",
        "editorUnicodeHighlight.border": "{{ orange }}",
        "editorUnicodeHighlight.background": "{{ orange }}29",
        "editorOverviewRuler.background": "{{ background }}",
        "editorOverviewRuler.border": "{{ border }}",
        "editorOverviewRuler.findMatchForeground": "{{ orange }}",
        "editorOverviewRuler.rangeHighlightForeground": "{{ accent }}99",
        "editorOverviewRuler.selectionHighlightForeground": "{{ accent }}",
        "editorOverviewRuler.wordHighlightForeground": "{{ accent }}99",
        "editorOverviewRuler.wordHighlightStrongForeground": "{{ accent }}",
        "editorOverviewRuler.wordHighlightTextForeground": "{{ accent }}99",
        "editorOverviewRuler.modifiedForeground": "{{ blue }}",
        "editorOverviewRuler.addedForeground": "{{ green }}",
        "editorOverviewRuler.deletedForeground": "{{ red }}",
        "editorOverviewRuler.errorForeground": "{{ red }}",
        "editorOverviewRuler.warningForeground": "{{ orange }}",
        "editorOverviewRuler.infoForeground": "{{ cyan }}",
        "editorOverviewRuler.bracketMatchForeground": "{{ border_focus }}",
        "editorOverviewRuler.currentContentForeground": "{{ cyan }}",
        "editorOverviewRuler.incomingContentForeground": "{{ green }}",
        "editorOverviewRuler.commonContentForeground": "{{ comment }}",
        "editorError.foreground": "{{ red }}",
        "editorError.background": "#00000000",
        "editorError.border": "#00000000",
        "editorWarning.foreground": "{{ orange }}",
        "editorWarning.background": "#00000000",
        "editorWarning.border": "#00000000",
        "editorInfo.foreground": "{{ cyan }}",
        "editorInfo.background": "#00000000",
        "editorInfo.border": "#00000000",
        "editorHint.foreground": "{{ hint }}",
        "editorHint.border": "#00000000",
        "problemsErrorIcon.foreground": "{{ red }}",
        "problemsWarningIcon.foreground": "{{ orange }}",
        "problemsInfoIcon.foreground": "{{ cyan }}",
        "editorUnnecessaryCode.opacity": "#000000a0",
        "editorUnnecessaryCode.border": "#00000000",
        "editorGutter.background": "{{ background }}",
        "editorGutter.modifiedBackground": "{{ blue }}",
        "editorGutter.addedBackground": "{{ green }}",
        "editorGutter.deletedBackground": "{{ red }}",
        "editorGutter.modifiedSecondaryBackground": "{{ blue }}99",
        "editorGutter.addedSecondaryBackground": "{{ green }}99",
        "editorGutter.deletedSecondaryBackground": "{{ red }}99",
        "editorGutter.commentRangeForeground": "{{ comment }}",
        "editorGutter.commentGlyphForeground": "{{ accent }}",
        "editorGutter.commentUnresolvedGlyphForeground": "{{ orange }}",
        "editorGutter.foldingControlForeground": "{{ comment }}",
        "editorCommentsWidget.resolvedBorder": "{{ green }}",
        "editorCommentsWidget.unresolvedBorder": "{{ orange }}",
        "editorCommentsWidget.rangeBackground": "{{ accent }}1a",
        "editorCommentsWidget.rangeActiveBackground": "{{ accent }}29",
        "editorCommentsWidget.replyInputBackground": "{{ background }}",
        "diffEditor.insertedTextBackground": "{{ green }}4d",
        "diffEditor.insertedTextBorder": "#00000000",
        "diffEditor.removedTextBackground": "{{ red }}4d",
        "diffEditor.removedTextBorder": "#00000000",
        "diffEditor.insertedLineBackground": "{{ green }}21",
        "diffEditor.removedLineBackground": "{{ red }}21",
        "diffEditor.border": "{{ border }}",
        "diffEditor.diagonalFill": "{{ muted }}",
        "diffEditor.unchangedRegionBackground": "{{ dark_background }}",
        "diffEditor.unchangedRegionForeground": "{{ comment }}",
        "diffEditor.unchangedRegionShadow": "#00000040",
        "diffEditor.unchangedCodeBackground": "#00000000",
        "diffEditor.move.border": "{{ cyan }}",
        "diffEditor.moveActive.border": "{{ orange }}",
        "diffEditorGutter.insertedLineBackground": "{{ green }}4d",
        "diffEditorGutter.removedLineBackground": "{{ red }}4d",
        "diffEditorOverview.insertedForeground": "{{ green }}",
        "diffEditorOverview.removedForeground": "{{ red }}",
        "multiDiffEditor.border": "{{ border }}",
        "multiDiffEditor.headerBackground": "{{ dark_background }}",
        "multiDiffEditor.background": "{{ background }}",
        "editorWidget.foreground": "{{ foreground }}",
        "editorWidget.background": "{{ dark_background }}",
        "editorWidget.border": "{{ border_focus }}",
        "editorWidget.resizeBorder": "{{ border_focus }}",
        "editorSuggestWidget.background": "{{ dark_background }}",
        "editorSuggestWidget.border": "{{ border_focus }}",
        "editorSuggestWidget.foreground": "{{ foreground }}",
        "editorSuggestWidget.focusHighlightForeground": "{{ accent }}",
        "editorSuggestWidget.highlightForeground": "{{ accent }}",
        "editorSuggestWidget.selectedBackground": "{{ mix background accent 16% }}",
        "editorSuggestWidget.selectedForeground": "{{ bright_foreground }}",
        "editorSuggestWidget.selectedIconForeground": "{{ bright_foreground }}",
        "editorSuggestWidgetStatus.foreground": "{{ comment }}",
        "editorHoverWidget.foreground": "{{ foreground }}",
        "editorHoverWidget.background": "{{ dark_background }}",
        "editorHoverWidget.border": "{{ border_focus }}",
        "editorHoverWidget.highlightForeground": "{{ accent }}",
        "editorHoverWidget.statusBarBackground": "{{ dark_background }}",
        "editorGhostText.foreground": "{{ comment }}",
        "editorGhostText.background": "#00000000",
        "editorGhostText.border": "#00000000",
        "editorStickyScroll.background": "{{ background }}",
        "editorStickyScroll.border": "{{ border }}",
        "editorStickyScroll.shadow": "#00000040",
        "editorStickyScrollHover.background": "{{ mix background foreground 6% }}",
        "debugExceptionWidget.background": "{{ dark_background }}",
        "debugExceptionWidget.border": "{{ red }}",
        "editorMarkerNavigation.background": "{{ dark_background }}",
        "editorMarkerNavigationError.background": "{{ red }}",
        "editorMarkerNavigationError.headerBackground": "{{ red }}21",
        "editorMarkerNavigationWarning.background": "{{ orange }}",
        "editorMarkerNavigationWarning.headerBackground": "{{ orange }}21",
        "editorMarkerNavigationInfo.background": "{{ cyan }}",
        "editorMarkerNavigationInfo.headerBackground": "{{ cyan }}21",
        "peekView.border": "{{ border_focus }}",
        "peekViewEditor.background": "{{ dark_background }}",
        "peekViewEditorGutter.background": "{{ dark_background }}",
        "peekViewEditor.matchHighlightBackground": "{{ green }}52",
        "peekViewEditor.matchHighlightBorder": "#00000000",
        "peekViewEditorStickyScroll.background": "{{ dark_background }}",
        "peekViewResult.background": "{{ dark_background }}",
        "peekViewResult.fileForeground": "{{ foreground }}",
        "peekViewResult.lineForeground": "{{ light_foreground }}",
        "peekViewResult.matchHighlightBackground": "{{ green }}52",
        "peekViewResult.selectionBackground": "{{ mix background accent 16% }}",
        "peekViewResult.selectionForeground": "{{ bright_foreground }}",
        "peekViewTitle.background": "{{ dark_background }}",
        "peekViewTitleDescription.foreground": "{{ comment }}",
        "peekViewTitleLabel.foreground": "{{ bright_foreground }}",
        "merge.currentHeaderBackground": "{{ cyan }}66",
        "merge.currentContentBackground": "{{ cyan }}29",
        "merge.incomingHeaderBackground": "{{ green }}66",
        "merge.incomingContentBackground": "{{ green }}29",
        "merge.commonHeaderBackground": "{{ muted }}",
        "merge.commonContentBackground": "{{ muted }}80",
        "merge.border": "{{ border }}",
        "mergeEditor.change.background": "{{ blue }}21",
        "mergeEditor.change.word.background": "{{ blue }}4d",
        "mergeEditor.changeBase.background": "{{ red }}21",
        "mergeEditor.changeBase.word.background": "{{ red }}4d",
        "mergeEditor.conflict.unhandledUnfocused.border": "{{ orange }}",
        "mergeEditor.conflict.unhandledFocused.border": "{{ orange }}",
        "mergeEditor.conflict.handledUnfocused.border": "{{ green }}",
        "mergeEditor.conflict.handledFocused.border": "{{ green }}",
        "mergeEditor.conflict.handled.minimapOverViewRuler": "{{ green }}",
        "mergeEditor.conflict.unhandled.minimapOverViewRuler": "{{ orange }}",
        "mergeEditor.conflictingLines.background": "{{ orange }}21",
        "panel.background": "{{ background }}",
        "panel.border": "{{ border }}",
        "panel.dropBorder": "{{ border_focus }}",
        "panelTitle.activeBorder": "{{ accent }}",
        "panelTitle.activeForeground": "{{ bright_foreground }}",
        "panelTitle.inactiveForeground": "{{ comment }}",
        "panelTitleBadge.background": "{{ accent }}",
        "panelTitleBadge.foreground": "{{ background }}",
        "panelInput.border": "{{ border }}",
        "panelSection.border": "{{ border }}",
        "panelSection.dropBackground": "{{ mix background accent 8% }}",
        "panelSectionHeader.background": "{{ background }}",
        "panelSectionHeader.foreground": "{{ bright_foreground }}",
        "panelSectionHeader.border": "{{ border }}",
        "panelStickyScroll.background": "{{ background }}",
        "outputView.background": "{{ background }}",
        "outputViewStickyScroll.background": "{{ background }}",
        "statusBar.background": "{{ dark_background }}",
        "statusBar.foreground": "{{ light_foreground }}",
        "statusBar.border": "{{ border }}",
        "statusBar.focusBorder": "{{ border_focus }}",
        "statusBar.debuggingBackground": "{{ orange }}",
        "statusBar.debuggingForeground": "{{ background }}",
        "statusBar.debuggingBorder": "{{ orange }}",
        "statusBar.noFolderBackground": "{{ dark_background }}",
        "statusBar.noFolderForeground": "{{ light_foreground }}",
        "statusBar.noFolderBorder": "{{ border }}",
        "statusBarItem.activeBackground": "{{ mix background accent 16% }}",
        "statusBarItem.hoverBackground": "{{ mix background foreground 6% }}",
        "statusBarItem.hoverForeground": "{{ foreground }}",
        "statusBarItem.focusBorder": "{{ border_focus }}",
        "statusBarItem.compactHoverBackground": "{{ mix background foreground 6% }}",
        "statusBarItem.prominentBackground": "{{ accent }}",
        "statusBarItem.prominentForeground": "{{ background }}",
        "statusBarItem.prominentHoverBackground": "{{ mix accent foreground 13% }}",
        "statusBarItem.prominentHoverForeground": "{{ background }}",
        "statusBarItem.remoteBackground": "{{ accent }}",
        "statusBarItem.remoteForeground": "{{ background }}",
        "statusBarItem.remoteHoverBackground": "{{ mix accent foreground 13% }}",
        "statusBarItem.remoteHoverForeground": "{{ background }}",
        "statusBarItem.errorBackground": "{{ red }}",
        "statusBarItem.errorForeground": "{{ background }}",
        "statusBarItem.errorHoverBackground": "{{ mix red foreground 13% }}",
        "statusBarItem.errorHoverForeground": "{{ background }}",
        "statusBarItem.warningBackground": "{{ orange }}",
        "statusBarItem.warningForeground": "{{ background }}",
        "statusBarItem.warningHoverBackground": "{{ mix orange foreground 13% }}",
        "statusBarItem.warningHoverForeground": "{{ background }}",
        "statusBarItem.offlineBackground": "{{ orange }}",
        "statusBarItem.offlineForeground": "{{ background }}",
        "titleBar.activeBackground": "{{ dark_background }}",
        "titleBar.activeForeground": "{{ foreground }}",
        "titleBar.inactiveBackground": "{{ dark_background }}",
        "titleBar.inactiveForeground": "{{ comment }}",
        "titleBar.border": "{{ border }}",
        "menubar.selectionForeground": "{{ bright_foreground }}",
        "menubar.selectionBackground": "{{ mix background accent 16% }}",
        "menubar.selectionBorder": "#00000000",
        "menu.foreground": "{{ foreground }}",
        "menu.background": "{{ dark_background }}",
        "menu.selectionForeground": "{{ bright_foreground }}",
        "menu.selectionBackground": "{{ mix background accent 16% }}",
        "menu.selectionBorder": "#00000000",
        "menu.separatorBackground": "{{ border }}",
        "menu.border": "{{ border_focus }}",
        "commandCenter.foreground": "{{ foreground }}",
        "commandCenter.activeForeground": "{{ bright_foreground }}",
        "commandCenter.background": "{{ background }}",
        "commandCenter.activeBackground": "{{ mix background foreground 6% }}",
        "commandCenter.border": "{{ border }}",
        "commandCenter.activeBorder": "{{ border_focus }}",
        "commandCenter.inactiveForeground": "{{ comment }}",
        "commandCenter.inactiveBorder": "{{ border }}",
        "commandCenter.debuggingBackground": "{{ orange }}33",
        "notificationCenter.border": "{{ border_focus }}",
        "notificationCenterHeader.foreground": "{{ bright_foreground }}",
        "notificationCenterHeader.background": "{{ dark_background }}",
        "notificationToast.border": "{{ border_focus }}",
        "notifications.foreground": "{{ foreground }}",
        "notifications.background": "{{ dark_background }}",
        "notifications.border": "{{ border }}",
        "notificationLink.foreground": "{{ link }}",
        "notificationsErrorIcon.foreground": "{{ red }}",
        "notificationsWarningIcon.foreground": "{{ orange }}",
        "notificationsInfoIcon.foreground": "{{ cyan }}",
        "banner.background": "{{ mix background accent 16% }}",
        "banner.foreground": "{{ bright_foreground }}",
        "banner.iconForeground": "{{ accent }}",
        "extensionButton.prominentBackground": "{{ accent }}",
        "extensionButton.prominentForeground": "{{ background }}",
        "extensionButton.prominentHoverBackground": "{{ mix accent foreground 13% }}",
        "extensionButton.background": "{{ accent }}",
        "extensionButton.foreground": "{{ background }}",
        "extensionButton.hoverBackground": "{{ mix accent foreground 13% }}",
        "extensionButton.separator": "{{ background }}66",
        "extensionBadge.remoteBackground": "{{ accent }}",
        "extensionBadge.remoteForeground": "{{ background }}",
        "extensionIcon.starForeground": "{{ yellow }}",
        "extensionIcon.verifiedForeground": "{{ accent }}",
        "extensionIcon.preReleaseForeground": "{{ orange }}",
        "extensionIcon.sponsorForeground": "{{ link }}",
        "pickerGroup.border": "{{ border }}",
        "pickerGroup.foreground": "{{ accent }}",
        "quickInput.background": "{{ dark_background }}",
        "quickInput.foreground": "{{ foreground }}",
        "quickInputList.focusBackground": "{{ mix background accent 16% }}",
        "quickInputList.focusForeground": "{{ bright_foreground }}",
        "quickInputList.focusIconForeground": "{{ bright_foreground }}",
        "quickInputTitle.background": "{{ dark_background }}",
        "keybindingLabel.background": "{{ dark_background }}",
        "keybindingLabel.foreground": "{{ foreground }}",
        "keybindingLabel.border": "{{ border }}",
        "keybindingLabel.bottomBorder": "{{ border }}",
        "keybindingTable.headerBackground": "{{ dark_background }}",
        "keybindingTable.rowsBackground": "{{ mix background foreground 6% }}",
        "terminal.background": "{{ background }}",
        "terminal.foreground": "{{ foreground }}",
        "terminal.border": "{{ border }}",
        "terminal.selectionBackground": "{{ selection }}",
        "terminal.inactiveSelectionBackground": "{{ mix background selection 60% }}",
        "terminal.findMatchBackground": "{{ orange }}66",
        "terminal.findMatchBorder": "{{ orange }}",
        "terminal.findMatchHighlightBackground": "{{ green }}52",
        "terminal.findMatchHighlightBorder": "#00000000",
        "terminal.hoverHighlightBackground": "{{ accent }}29",
        "terminal.dropBackground": "{{ mix background accent 8% }}",
        "terminal.tab.activeBorder": "{{ accent }}",
        "terminalCursor.background": "{{ background }}",
        "terminalCursor.foreground": "{{ bright_foreground }}",
        "terminal.ansiBlack": "{{ background }}",
        "terminal.ansiRed": "{{ red }}",
        "terminal.ansiGreen": "{{ green }}",
        "terminal.ansiYellow": "{{ yellow }}",
        "terminal.ansiBlue": "{{ blue }}",
        "terminal.ansiMagenta": "{{ magenta }}",
        "terminal.ansiCyan": "{{ cyan }}",
        "terminal.ansiWhite": "{{ foreground }}",
        "terminal.ansiBrightBlack": "{{ comment }}",
        "terminal.ansiBrightRed": "{{ bright_red }}",
        "terminal.ansiBrightGreen": "{{ bright_green }}",
        "terminal.ansiBrightYellow": "{{ bright_yellow }}",
        "terminal.ansiBrightBlue": "{{ bright_blue }}",
        "terminal.ansiBrightMagenta": "{{ bright_magenta }}",
        "terminal.ansiBrightCyan": "{{ bright_cyan }}",
        "terminal.ansiBrightWhite": "{{ bright_foreground }}",
        "terminalCommandDecoration.defaultBackground": "{{ comment }}",
        "terminalCommandDecoration.successBackground": "{{ green }}",
        "terminalCommandDecoration.errorBackground": "{{ red }}",
        "terminalOverviewRuler.border": "{{ border }}",
        "terminalOverviewRuler.cursorForeground": "{{ bright_foreground }}",
        "terminalOverviewRuler.findMatchForeground": "{{ orange }}",
        "terminalStickyScroll.background": "{{ background }}",
        "terminalStickyScroll.border": "{{ border }}",
        "terminalStickyScrollHover.background": "{{ mix background foreground 6% }}",
        "debugToolBar.background": "{{ dark_background }}",
        "debugToolBar.border": "{{ border_focus }}",
        "debugView.stateLabelForeground": "{{ bright_foreground }}",
        "debugView.stateLabelBackground": "{{ mix background accent 16% }}",
        "debugView.valueChangedHighlight": "{{ blue }}66",
        "debugView.exceptionLabelForeground": "{{ background }}",
        "debugView.exceptionLabelBackground": "{{ red }}",
        "debugTokenExpression.name": "{{ orange }}",
        "debugTokenExpression.type": "{{ cyan }}",
        "debugTokenExpression.value": "{{ foreground }}",
        "debugTokenExpression.string": "{{ yellow }}",
        "debugTokenExpression.boolean": "{{ blue }}",
        "debugTokenExpression.number": "{{ blue }}",
        "debugTokenExpression.error": "{{ red }}",
        "debugIcon.breakpointForeground": "{{ red }}",
        "debugIcon.breakpointDisabledForeground": "{{ comment }}",
        "debugIcon.breakpointUnverifiedForeground": "{{ orange }}",
        "debugIcon.breakpointCurrentStackframeForeground": "{{ orange }}",
        "debugIcon.breakpointStackframeForeground": "{{ green }}",
        "debugIcon.startForeground": "{{ green }}",
        "debugIcon.pauseForeground": "{{ orange }}",
        "debugIcon.stopForeground": "{{ red }}",
        "debugIcon.disconnectForeground": "{{ red }}",
        "debugIcon.restartForeground": "{{ green }}",
        "debugIcon.stepOverForeground": "{{ accent }}",
        "debugIcon.stepIntoForeground": "{{ accent }}",
        "debugIcon.stepOutForeground": "{{ accent }}",
        "debugIcon.continueForeground": "{{ green }}",
        "debugIcon.stepBackForeground": "{{ accent }}",
        "debugConsole.infoForeground": "{{ cyan }}",
        "debugConsole.warningForeground": "{{ orange }}",
        "debugConsole.errorForeground": "{{ red }}",
        "debugConsole.sourceForeground": "{{ foreground }}",
        "debugConsoleInputIcon.foreground": "{{ accent }}",
        "editor.stackFrameHighlightBackground": "{{ orange }}29",
        "editor.focusedStackFrameHighlightBackground": "{{ green }}29",
        "testing.iconFailed": "{{ red }}",
        "testing.iconErrored": "{{ red }}",
        "testing.iconPassed": "{{ green }}",
        "testing.runAction": "{{ green }}",
        "testing.iconQueued": "{{ orange }}",
        "testing.iconUnset": "{{ comment }}",
        "testing.iconSkipped": "{{ comment }}",
        "testing.peekBorder": "{{ border_focus }}",
        "testing.peekHeaderBackground": "{{ dark_background }}",
        "testing.message.error.decorationForeground": "{{ red }}",
        "testing.message.error.lineBackground": "{{ red }}21",
        "testing.message.info.decorationForeground": "{{ cyan }}",
        "testing.message.info.lineBackground": "{{ cyan }}21",
        "welcomePage.background": "{{ background }}",
        "welcomePage.tileBackground": "{{ dark_background }}",
        "welcomePage.tileHoverBackground": "{{ mix background foreground 6% }}",
        "welcomePage.tileBorder": "{{ border }}",
        "welcomePage.progress.background": "{{ muted }}",
        "welcomePage.progress.foreground": "{{ accent }}",
        "walkThrough.embeddedEditorBackground": "{{ dark_background }}",
        "walkthrough.stepTitle.foreground": "{{ bright_foreground }}",
        "gitDecoration.addedResourceForeground": "{{ green }}",
        "gitDecoration.modifiedResourceForeground": "{{ blue }}",
        "gitDecoration.deletedResourceForeground": "{{ red }}",
        "gitDecoration.renamedResourceForeground": "{{ cyan }}",
        "gitDecoration.stageModifiedResourceForeground": "{{ blue }}",
        "gitDecoration.stageDeletedResourceForeground": "{{ red }}",
        "gitDecoration.untrackedResourceForeground": "{{ green }}",
        "gitDecoration.ignoredResourceForeground": "{{ comment }}",
        "gitDecoration.conflictingResourceForeground": "{{ orange }}",
        "gitDecoration.submoduleResourceForeground": "{{ cyan }}",
        "settings.headerForeground": "{{ bright_foreground }}",
        "settings.modifiedItemIndicator": "{{ blue }}",
        "settings.dropdownBackground": "{{ background }}",
        "settings.dropdownForeground": "{{ foreground }}",
        "settings.dropdownBorder": "{{ border }}",
        "settings.dropdownListBorder": "{{ border_focus }}",
        "settings.checkboxBackground": "{{ background }}",
        "settings.checkboxForeground": "{{ foreground }}",
        "settings.checkboxBorder": "{{ border }}",
        "settings.textInputBackground": "{{ background }}",
        "settings.textInputForeground": "{{ foreground }}",
        "settings.textInputBorder": "{{ border }}",
        "settings.numberInputBackground": "{{ background }}",
        "settings.numberInputForeground": "{{ foreground }}",
        "settings.numberInputBorder": "{{ border }}",
        "settings.rowHoverBackground": "{{ mix background foreground 6% }}",
        "settings.focusedRowBackground": "{{ mix background foreground 6% }}",
        "settings.focusedRowBorder": "{{ border_focus }}",
        "settings.headerBorder": "{{ border }}",
        "settings.sashBorder": "{{ border }}",
        "settings.settingsHeaderHoverForeground": "{{ accent }}",
        "breadcrumb.foreground": "{{ comment }}",
        "breadcrumb.background": "{{ background }}",
        "breadcrumb.focusForeground": "{{ foreground }}",
        "breadcrumb.activeSelectionForeground": "{{ bright_foreground }}",
        "breadcrumbPicker.background": "{{ dark_background }}",
        "editor.snippetTabstopHighlightBackground": "{{ accent }}29",
        "editor.snippetTabstopHighlightBorder": "#00000000",
        "editor.snippetFinalTabstopHighlightBackground": "#00000000",
        "editor.snippetFinalTabstopHighlightBorder": "{{ border_focus }}",
        "symbolIcon.arrayForeground": "{{ orange }}",
        "symbolIcon.booleanForeground": "{{ blue }}",
        "symbolIcon.classForeground": "{{ cyan }}",
        "symbolIcon.colorForeground": "{{ yellow }}",
        "symbolIcon.constantForeground": "{{ blue }}",
        "symbolIcon.constructorForeground": "{{ cyan }}",
        "symbolIcon.enumeratorForeground": "{{ cyan }}",
        "symbolIcon.enumeratorMemberForeground": "{{ blue }}",
        "symbolIcon.eventForeground": "{{ magenta }}",
        "symbolIcon.fieldForeground": "{{ orange }}",
        "symbolIcon.fileForeground": "{{ light_foreground }}",
        "symbolIcon.folderForeground": "{{ accent }}",
        "symbolIcon.functionForeground": "{{ green }}",
        "symbolIcon.interfaceForeground": "{{ cyan }}",
        "symbolIcon.keyForeground": "{{ orange }}",
        "symbolIcon.keywordForeground": "{{ magenta }}",
        "symbolIcon.methodForeground": "{{ green }}",
        "symbolIcon.moduleForeground": "{{ cyan }}",
        "symbolIcon.namespaceForeground": "{{ cyan }}",
        "symbolIcon.nullForeground": "{{ blue }}",
        "symbolIcon.numberForeground": "{{ blue }}",
        "symbolIcon.objectForeground": "{{ cyan }}",
        "symbolIcon.operatorForeground": "{{ magenta }}",
        "symbolIcon.packageForeground": "{{ cyan }}",
        "symbolIcon.propertyForeground": "{{ orange }}",
        "symbolIcon.referenceForeground": "{{ link }}",
        "symbolIcon.snippetForeground": "{{ light_foreground }}",
        "symbolIcon.stringForeground": "{{ yellow }}",
        "symbolIcon.structForeground": "{{ cyan }}",
        "symbolIcon.textForeground": "{{ light_foreground }}",
        "symbolIcon.typeParameterForeground": "{{ magenta }}",
        "symbolIcon.unitForeground": "{{ blue }}",
        "symbolIcon.variableForeground": "{{ foreground }}",
        "notebook.editorBackground": "{{ background }}",
        "notebook.cellBorderColor": "{{ border }}",
        "notebook.cellHoverBackground": "{{ mix background foreground 6% }}",
        "notebook.cellInsertionIndicator": "{{ border_focus }}",
        "notebook.cellStatusBarItemHoverBackground": "{{ mix background foreground 6% }}",
        "notebook.cellToolbarSeparator": "{{ border }}",
        "notebook.cellEditorBackground": "{{ dark_background }}",
        "notebook.focusedCellBackground": "{{ mix background foreground 6% }}",
        "notebook.focusedCellBorder": "{{ border_focus }}",
        "notebook.focusedEditorBorder": "{{ border_focus }}",
        "notebook.inactiveFocusedCellBorder": "{{ border }}",
        "notebook.inactiveSelectedCellBorder": "{{ border }}",
        "notebook.outputContainerBackgroundColor": "{{ dark_background }}",
        "notebook.outputContainerBorderColor": "{{ border }}",
        "notebook.selectedCellBackground": "{{ mix background accent 8% }}",
        "notebook.selectedCellBorder": "{{ border }}",
        "notebook.symbolHighlightBackground": "{{ accent }}29",
        "notebookStatusErrorIcon.foreground": "{{ red }}",
        "notebookStatusRunningIcon.foreground": "{{ accent }}",
        "notebookStatusSuccessIcon.foreground": "{{ green }}",
        "notebookEditorOverviewRuler.runningCellForeground": "{{ accent }}",
        "charts.foreground": "{{ foreground }}",
        "charts.lines": "{{ border }}",
        "charts.red": "{{ red }}",
        "charts.blue": "{{ blue }}",
        "charts.yellow": "{{ yellow }}",
        "charts.orange": "{{ orange }}",
        "charts.green": "{{ green }}",
        "charts.purple": "{{ magenta }}",
        "ports.iconRunningProcessForeground": "{{ green }}",
        "commentsView.resolvedIcon": "{{ green }}",
        "commentsView.unresolvedIcon": "{{ orange }}",
        "editorWatermark.foreground": "{{ comment }}",
        "inlineChat.background": "{{ dark_background }}",
        "inlineChat.foreground": "{{ foreground }}",
        "inlineChat.border": "{{ border_focus }}",
        "inlineChat.shadow": "#00000040",
        "inlineChatInput.background": "{{ background }}",
        "inlineChatInput.border": "{{ border }}",
        "inlineChatInput.focusBorder": "{{ border_focus }}",
        "inlineChatInput.placeholderForeground": "{{ comment }}",
        "inlineChatDiff.inserted": "{{ green }}4d",
        "inlineChatDiff.removed": "{{ red }}4d",
        "chat.requestBackground": "{{ dark_background }}",
        "chat.requestBorder": "{{ border }}",
        "chat.slashCommandBackground": "{{ mix background accent 16% }}",
        "chat.slashCommandForeground": "{{ bright_foreground }}",
        "chat.avatarBackground": "{{ lighter_background }}",
        "chat.avatarForeground": "{{ foreground }}"
    },
    "tokenColors": [
        {
            "name": "Comment",
            "scope": [
                "comment",
                "punctuation.definition.comment",
                "comment.block.documentation"
            ],
            "settings": {
                "foreground": "{{ comment }}",
                "fontStyle": "italic"
            }
        },
        {
            "name": "Comment tag",
            "scope": [
                "comment storage.type",
                "comment keyword.other",
                "comment entity.name.type",
                "comment variable.parameter"
            ],
            "settings": {
                "foreground": "{{ cyan }}",
                "fontStyle": "italic"
            }
        },
        {
            "name": "Text",
            "scope": [
                "source",
                "text",
                "variable",
                "variable.other.readwrite",
                "meta.embedded"
            ],
            "settings": {
                "foreground": "{{ foreground }}",
                "fontStyle": ""
            }
        },
        {
            "name": "Builtin variable",
            "scope": [
                "variable.language",
                "variable.language.this",
                "variable.language.self",
                "variable.language.super",
                "variable.parameter.function.language.special.self.python",
                "support.variable",
                "support.variable.magic.python"
            ],
            "settings": {
                "foreground": "{{ blue }}",
                "fontStyle": "italic"
            }
        },
        {
            "name": "Parameter",
            "scope": [
                "variable.parameter",
                "entity.name.variable.parameter",
                "meta.function.parameters variable.other",
                "variable.parameter.function"
            ],
            "settings": {
                "foreground": "{{ orange }}",
                "fontStyle": "italic"
            }
        },
        {
            "name": "Property",
            "scope": [
                "variable.other.property",
                "variable.other.object.property",
                "variable.other.member",
                "meta.object-literal.key",
                "support.type.property-name",
                "meta.mapping.key string",
                "entity.name.tag.yaml",
                "keyword.key.toml",
                "support.type.property-name.toml",
                "keyword.other.definition.ini",
                "entity.name.variable.field"
            ],
            "settings": {
                "foreground": "{{ orange }}",
                "fontStyle": ""
            }
        },
        {
            "name": "Constant",
            "scope": [
                "constant",
                "constant.numeric",
                "constant.language.boolean",
                "variable.other.constant",
                "variable.other.enummember",
                "entity.name.constant",
                "constant.other.symbol",
                "keyword.other.unit",
                "support.constant"
            ],
            "settings": {
                "foreground": "{{ blue }}",
                "fontStyle": ""
            }
        },
        {
            "name": "Builtin constant",
            "scope": [
                "constant.language",
                "constant.language.null",
                "constant.language.undefined",
                "constant.language.nil",
                "constant.language.none"
            ],
            "settings": {
                "foreground": "{{ blue }}",
                "fontStyle": "italic"
            }
        },
        {
            "name": "Character",
            "scope": [
                "constant.character",
                "constant.character.escape",
                "constant.other.placeholder",
                "constant.character.format.placeholder",
                "constant.other.character-class.escape"
            ],
            "settings": {
                "foreground": "{{ magenta }}",
                "fontStyle": ""
            }
        },
        {
            "name": "String",
            "scope": [
                "string",
                "string.quoted",
                "string.template",
                "punctuation.definition.string",
                "string.unquoted"
            ],
            "settings": {
                "foreground": "{{ yellow }}",
                "fontStyle": ""
            }
        },
        {
            "name": "Regexp",
            "scope": [
                "string.regexp",
                "string.regexp punctuation.definition.string",
                "constant.other.character-class.regexp",
                "keyword.operator.quantifier.regexp",
                "keyword.control.anchor.regexp"
            ],
            "settings": {
                "foreground": "{{ red }}",
                "fontStyle": ""
            }
        },
        {
            "name": "Interpolation",
            "scope": [
                "punctuation.definition.template-expression",
                "punctuation.section.embedded",
                "punctuation.section.interpolation",
                "punctuation.definition.interpolation",
                "punctuation.special"
            ],
            "settings": {
                "foreground": "{{ magenta }}",
                "fontStyle": ""
            }
        },
        {
            "name": "Keyword",
            "scope": [
                "keyword",
                "keyword.control",
                "keyword.operator",
                "keyword.declaration",
                "keyword.other",
                "storage",
                "storage.type",
                "storage.modifier",
                "keyword.control.import",
                "keyword.control.directive",
                "meta.preprocessor",
                "punctuation.definition.directive",
                "punctuation.definition.preprocessor"
            ],
            "settings": {
                "foreground": "{{ magenta }}",
                "fontStyle": ""
            }
        },
        {
            "name": "Operator",
            "scope": [
                "keyword.operator.assignment",
                "keyword.operator.arithmetic",
                "keyword.operator.comparison",
                "keyword.operator.logical",
                "keyword.operator.ternary",
                "punctuation.accessor",
                "punctuation.separator.key-value"
            ],
            "settings": {
                "foreground": "{{ magenta }}",
                "fontStyle": ""
            }
        },
        {
            "name": "Type",
            "scope": [
                "entity.name.type",
                "entity.name.class",
                "entity.name.struct",
                "entity.name.enum",
                "entity.name.union",
                "entity.name.trait",
                "entity.name.interface",
                "entity.name.type.class",
                "entity.name.type.interface",
                "entity.name.type.enum",
                "entity.other.inherited-class",
                "support.type",
                "support.class",
                "storage.type.primitive",
                "storage.type.built-in",
                "storage.type.numeric",
                "storage.type.string",
                "storage.type.boolean",
                "storage.type.byte",
                "storage.type.rune",
                "storage.type.uintptr",
                "storage.type.error",
                "support.type.primitive",
                "support.type.builtin",
                "entity.name.type.lifetime"
            ],
            "settings": {
                "foreground": "{{ cyan }}",
                "fontStyle": "italic"
            }
        },
        {
            "name": "Type parameter",
            "scope": [
                "entity.name.type.parameter",
                "storage.type.generic",
                "entity.name.type.type-parameter"
            ],
            "settings": {
                "foreground": "{{ magenta }}",
                "fontStyle": "italic"
            }
        },
        {
            "name": "Module",
            "scope": [
                "entity.name.namespace",
                "entity.name.module",
                "entity.name.package",
                "entity.name.type.module",
                "entity.name.type.namespace",
                "support.module",
                "support.other.namespace",
                "storage.modifier.import",
                "storage.modifier.package"
            ],
            "settings": {
                "foreground": "{{ cyan }}",
                "fontStyle": ""
            }
        },
        {
            "name": "Function",
            "scope": [
                "entity.name.function",
                "meta.function-call",
                "variable.function",
                "support.function.any-method",
                "entity.name.function.macro",
                "support.function.macro",
                "entity.name.command",
                "entity.name.function.target"
            ],
            "settings": {
                "foreground": "{{ green }}",
                "fontStyle": ""
            }
        },
        {
            "name": "Builtin function",
            "scope": [
                "support.function",
                "support.function.builtin",
                "support.function.magic",
                "keyword.other.special-method"
            ],
            "settings": {
                "foreground": "{{ cyan }}",
                "fontStyle": ""
            }
        },
        {
            "name": "Constructor",
            "scope": [
                "entity.name.function.constructor",
                "meta.class.instance.constructor",
                "new.expr entity.name.type"
            ],
            "settings": {
                "foreground": "{{ cyan }}",
                "fontStyle": ""
            }
        },
        {
            "name": "Attribute",
            "scope": [
                "meta.decorator",
                "entity.name.function.decorator",
                "punctuation.decorator",
                "meta.annotation",
                "storage.type.annotation",
                "punctuation.definition.annotation",
                "meta.attribute",
                "entity.name.type.attribute",
                "entity.other.attribute-name"
            ],
            "settings": {
                "foreground": "{{ green }}",
                "fontStyle": "italic"
            }
        },
        {
            "name": "Label",
            "scope": [
                "entity.name.label",
                "punctuation.definition.label"
            ],
            "settings": {
                "foreground": "{{ blue }}",
                "fontStyle": "italic"
            }
        },
        {
            "name": "Tag",
            "scope": [
                "entity.name.tag",
                "support.class.component",
                "entity.name.tag.html",
                "entity.name.tag.css",
                "entity.name.tag.reference"
            ],
            "settings": {
                "foreground": "{{ cyan }}",
                "fontStyle": ""
            }
        },
        {
            "name": "CSS class",
            "scope": [
                "entity.other.attribute-name.class",
                "entity.other.attribute-name.class.css"
            ],
            "settings": {
                "foreground": "{{ cyan }}",
                "fontStyle": "italic"
            }
        },
        {
            "name": "CSS id",
            "scope": [
                "entity.other.attribute-name.id",
                "entity.other.attribute-name.id.css"
            ],
            "settings": {
                "foreground": "{{ blue }}",
                "fontStyle": ""
            }
        },
        {
            "name": "CSS pseudo",
            "scope": [
                "entity.other.attribute-name.pseudo-class",
                "entity.other.attribute-name.pseudo-element"
            ],
            "settings": {
                "foreground": "{{ green }}",
                "fontStyle": "italic"
            }
        },
        {
            "name": "Section",
            "scope": [
                "entity.other.attribute-name.table.toml",
                "support.type.property-name.table.toml",
                "entity.name.section.group-title.ini"
            ],
            "settings": {
                "foreground": "{{ cyan }}",
                "fontStyle": "italic"
            }
        },
        {
            "name": "Punctuation",
            "scope": [
                "punctuation",
                "meta.brace",
                "meta.bracket",
                "punctuation.definition.tag",
                "punctuation.separator",
                "punctuation.terminator",
                "punctuation.section",
                "punctuation.definition.block",
                "punctuation.definition.parameters",
                "punctuation.definition.array",
                "punctuation.definition.dictionary"
            ],
            "settings": {
                "foreground": "{{ light_foreground }}",
                "fontStyle": ""
            }
        },
        {
            "name": "Invalid",
            "scope": [
                "invalid",
                "invalid.illegal"
            ],
            "settings": {
                "foreground": "{{ red }}",
                "fontStyle": "underline"
            }
        },
        {
            "name": "Deprecated",
            "scope": [
                "invalid.deprecated"
            ],
            "settings": {
                "foreground": "{{ orange }}",
                "fontStyle": "strikethrough"
            }
        },
        {
            "name": "Heading",
            "scope": [
                "markup.heading",
                "entity.name.section.markdown",
                "punctuation.definition.heading.markdown",
                "markup.heading.1",
                "heading.1.markdown",
                "markup.heading.1.markdown"
            ],
            "settings": {
                "foreground": "{{ accent }}",
                "fontStyle": "bold"
            }
        },
        {
            "name": "Heading 2",
            "scope": [
                "markup.heading.2",
                "heading.2.markdown",
                "markup.heading.2.markdown",
                "heading.2.markdown entity.name.section.markdown",
                "heading.2.markdown punctuation.definition.heading.markdown",
                "markup.heading.2.markdown entity.name.section.markdown",
                "markup.heading.2.markdown punctuation.definition.heading"
            ],
            "settings": {
                "foreground": "{{ mix accent foreground 13% }}",
                "fontStyle": "bold"
            }
        },
        {
            "name": "Heading 3",
            "scope": [
                "markup.heading.3",
                "heading.3.markdown",
                "markup.heading.3.markdown",
                "heading.3.markdown entity.name.section.markdown",
                "heading.3.markdown punctuation.definition.heading.markdown",
                "markup.heading.3.markdown entity.name.section.markdown",
                "markup.heading.3.markdown punctuation.definition.heading"
            ],
            "settings": {
                "foreground": "{{ mix accent foreground 26% }}",
                "fontStyle": "bold"
            }
        },
        {
            "name": "Heading 4",
            "scope": [
                "markup.heading.4",
                "heading.4.markdown",
                "markup.heading.4.markdown",
                "heading.4.markdown entity.name.section.markdown",
                "heading.4.markdown punctuation.definition.heading.markdown",
                "markup.heading.4.markdown entity.name.section.markdown",
                "markup.heading.4.markdown punctuation.definition.heading"
            ],
            "settings": {
                "foreground": "{{ mix accent foreground 39% }}",
                "fontStyle": "bold"
            }
        },
        {
            "name": "Heading 5",
            "scope": [
                "markup.heading.5",
                "heading.5.markdown",
                "markup.heading.5.markdown",
                "heading.5.markdown entity.name.section.markdown",
                "heading.5.markdown punctuation.definition.heading.markdown",
                "markup.heading.5.markdown entity.name.section.markdown",
                "markup.heading.5.markdown punctuation.definition.heading"
            ],
            "settings": {
                "foreground": "{{ mix accent foreground 52% }}",
                "fontStyle": "bold"
            }
        },
        {
            "name": "Heading 6",
            "scope": [
                "markup.heading.6",
                "heading.6.markdown",
                "markup.heading.6.markdown",
                "heading.6.markdown entity.name.section.markdown",
                "heading.6.markdown punctuation.definition.heading.markdown",
                "markup.heading.6.markdown entity.name.section.markdown",
                "markup.heading.6.markdown punctuation.definition.heading"
            ],
            "settings": {
                "foreground": "{{ mix accent foreground 65% }}",
                "fontStyle": "bold"
            }
        },
        {
            "name": "Bold",
            "scope": [
                "markup.bold",
                "punctuation.definition.bold"
            ],
            "settings": {
                "foreground": "{{ bright_foreground }}",
                "fontStyle": "bold"
            }
        },
        {
            "name": "Italic",
            "scope": [
                "markup.italic",
                "punctuation.definition.italic"
            ],
            "settings": {
                "foreground": "{{ foreground }}",
                "fontStyle": "italic"
            }
        },
        {
            "name": "Bold italic",
            "scope": [
                "markup.bold markup.italic",
                "markup.italic markup.bold"
            ],
            "settings": {
                "foreground": "{{ bright_foreground }}",
                "fontStyle": "bold italic"
            }
        },
        {
            "name": "Strikethrough",
            "scope": [
                "markup.strikethrough"
            ],
            "settings": {
                "foreground": "{{ comment }}",
                "fontStyle": "strikethrough"
            }
        },
        {
            "name": "Link text",
            "scope": [
                "string.other.link",
                "string.other.link.title",
                "string.other.link.description",
                "meta.link.inline.description",
                "meta.link.reference.description",
                "markup.underline.link.image",
                "constant.other.reference.link"
            ],
            "settings": {
                "foreground": "{{ link }}",
                "fontStyle": "underline"
            }
        },
        {
            "name": "Link url",
            "scope": [
                "markup.underline.link",
                "meta.link.inline markup.underline.link",
                "markup.underline.link.markdown"
            ],
            "settings": {
                "foreground": "{{ comment }}",
                "fontStyle": "underline"
            }
        },
        {
            "name": "Inline code",
            "scope": [
                "markup.inline.raw",
                "markup.raw.inline",
                "markup.inline.raw.string.markdown"
            ],
            "settings": {
                "foreground": "{{ cyan }}",
                "fontStyle": ""
            }
        },
        {
            "name": "Code block",
            "scope": [
                "markup.raw.block",
                "markup.fenced_code.block",
                "markup.raw.code-fence"
            ],
            "settings": {
                "foreground": "{{ foreground }}",
                "fontStyle": ""
            }
        },
        {
            "name": "Code fence",
            "scope": [
                "punctuation.definition.markdown",
                "punctuation.definition.raw.code-fence",
                "fenced_code.block.language",
                "punctuation.definition.raw"
            ],
            "settings": {
                "foreground": "{{ comment }}",
                "fontStyle": ""
            }
        },
        {
            "name": "Quote",
            "scope": [
                "markup.quote",
                "punctuation.definition.quote.begin.markdown",
                "punctuation.definition.blockquote"
            ],
            "settings": {
                "foreground": "{{ light_foreground }}",
                "fontStyle": "italic"
            }
        },
        {
            "name": "List",
            "scope": [
                "punctuation.definition.list.begin.markdown",
                "punctuation.definition.list_item",
                "markup.list.numbered.bullet",
                "markup.list punctuation.definition.list"
            ],
            "settings": {
                "foreground": "{{ accent }}",
                "fontStyle": ""
            }
        },
        {
            "name": "Rule",
            "scope": [
                "meta.separator.markdown",
                "punctuation.definition.thematic-break"
            ],
            "settings": {
                "foreground": "{{ comment }}",
                "fontStyle": ""
            }
        },
        {
            "name": "Math",
            "scope": [
                "markup.math",
                "markup.raw.math"
            ],
            "settings": {
                "foreground": "{{ blue }}",
                "fontStyle": ""
            }
        },
        {
            "name": "Inserted",
            "scope": [
                "markup.inserted",
                "punctuation.definition.inserted",
                "meta.diff.header.to-file"
            ],
            "settings": {
                "foreground": "{{ green }}",
                "fontStyle": ""
            }
        },
        {
            "name": "Deleted",
            "scope": [
                "markup.deleted",
                "punctuation.definition.deleted",
                "meta.diff.header.from-file"
            ],
            "settings": {
                "foreground": "{{ red }}",
                "fontStyle": ""
            }
        },
        {
            "name": "Changed",
            "scope": [
                "markup.changed",
                "punctuation.definition.changed"
            ],
            "settings": {
                "foreground": "{{ blue }}",
                "fontStyle": ""
            }
        },
        {
            "name": "Diff header",
            "scope": [
                "meta.diff.header",
                "meta.diff.index"
            ],
            "settings": {
                "foreground": "{{ accent }}",
                "fontStyle": "bold"
            }
        },
        {
            "name": "Diff range",
            "scope": [
                "meta.diff.range"
            ],
            "settings": {
                "foreground": "{{ cyan }}",
                "fontStyle": ""
            }
        }
    ]
}
