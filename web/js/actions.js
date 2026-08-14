// ═══════════════════════════════════════════════════════
// § 30 · DELEGATED EVENT HANDLING (CSP: no inline handlers)
// ═══════════════════════════════════════════════════════
// Inline handlers (onclick="...") need 'unsafe-inline' in the CSP
// script-src, which also lets any XSS-injected HTML execute arbitrary
// script. Every interactive element now carries data-action (+ optional
// data-arg) instead; ONE delegated listener per event type looks the
// action name up in the ACTIONS table below and calls the matching
// function. Only the names registered here can ever be invoked — an
// attacker who manages to inject a rogue data-action attribute can at
// most call one of these pre-approved app functions (with a data-arg of
// their choosing, no worse than the input that function already accepts
// from its normal callers), never run arbitrary new code.

const ACTIONS = {
  // Login / auth
  'login-goto': (el) => loginGoTo(el.dataset.arg),
  'login-with-google': () => loginWithGoogle(),
  'login-with-email': () => loginWithEmail(),
  'register-with-email': () => registerWithEmail(),
  'reset-password': () => resetPassword(),
  'login-with-google-for-create': () => loginWithGoogleForCreate(),
  'register-for-create': () => registerForCreate(),
  'join-with-code': () => joinWithCode(),
  'complete-setup': () => completeSetup(),
  'back-from-setup': () => backFromSetup(),
  'finish-setup': () => finishSetup(),
  'copy-code': (el) => copyCode(el.dataset.arg),

  // Shell / navigation
  'toggle-sidebar': () => toggleSidebar(),
  'toggle-sidebar-collapse': () => toggleSidebarCollapse(),
  'navigate': (el) => navigate(el.dataset.arg),
  'set-theme': (el) => setTheme(el.dataset.arg),
  'show-add-modal': () => showAddModal(),
  'sign-out': () => signOut(),
  'quick-log': () => { navigate('daily'); showAddLogModal(); },
  'quick-improvement': () => { navigate('robot'); openAddImprovement(); },
  'quick-timer': () => { navigate('scoring'); setTimeout(() => startTimer('robot'), 150); },
  'install-pwa': () => installPWA(),

  // Daily log
  'filter-logs': () => filterLogs(),
  'show-add-log-modal': () => showAddLogModal(),
  'toggle-image-zoom': (el) => toggleImageZoom(el),
  'edit-log': (el) => editLog(Number(el.dataset.id)),
  'delete-log': (el) => deleteLog(Number(el.dataset.id)),
  'close-dynamic-overlay': (el) => closeDynamicOverlay(el),
  'save-edited-log': (el) => saveEditedLog(el, Number(el.dataset.id)),

  // Values
  'switch-values-tab': (el) => switchValuesTab(el.dataset.arg),
  'import-official-rubric': (el) => importOfficialRubric(el.dataset.arg),
  'add-custom-rubric': (el) => addCustomRubric(el.dataset.arg),
  'show-add-sticky-modal': () => showAddStickyModal(),

  // Rubrics (shared: values / robot / innovation / scoring tabs)
  'set-score': (el) => setScore(el.dataset.category, Number(el.dataset.id), Number(el.dataset.score)),
  'set-notes': (el) => setNotes(el.dataset.category, Number(el.dataset.id), el.value),
  'delete-rubric': (el) => deleteRubric(el.dataset.category, Number(el.dataset.id)),

  // Robot
  'open-add-improvement': () => openAddImprovement(),
  'handle-robot-photo': (el, e) => handleRobotPhoto(e),
  'filter-missions': (el) => filterMissions(el.dataset.arg),
  'filter-robot-by-mission': () => filterRobotByMission(),
  'toggle-mission': (el) => toggleMission(Number(el.dataset.id)),
  'set-mission-status': (el) => setMissionStatus(Number(el.dataset.id), el.dataset.status),
  'open-mission-extra': (el) => openMissionExtraModal(Number(el.dataset.id)),
  'save-mission-extra': () => saveMissionExtra(),
  'toggle-mission-bonus': (el) => toggleMissionBonus(Number(el.dataset.id)),
  'import-missions-json': (el) => importMissionsJson(el),
  'confirm-mission-import': () => confirmMissionImport(),
  'cancel-mission-import': () => cancelMissionImport(),
  'reset-missions-default': () => resetMissionsToDefault(),
  'open-video-select': () => openVideoSelect(),

  // Innovation
  'switch-innov-tab': (el) => switchInnovTab(el.dataset.arg),
  'show-add-finding-modal': () => showAddFindingModal(),
  'show-add-interview-modal': () => showAddInterviewModal(),
  'start-recording': () => startRecording(),
  'open-innov-step-modal': (el) => openInnovStepModal(el.dataset.arg),
  'delete-interview': (el) => deleteInterview(Number(el.dataset.id)),

  // Scoring
  'switch-scoring-tab': (el) => switchScoringTab(el.dataset.arg),
  'jump-to-phase': (el) => jumpToPhase(Number(el.dataset.arg)),
  'start-judging-timer': () => startJudgingTimer(),
  'reset-judging-timer': () => resetJudgingTimer(),
  'next-judging-phase': () => nextJudgingPhase(),
  'open-official-rubrics-site': () => window.open('https://fll-events.firstisrael.org.il/tools/rubrics', '_blank'),
  'toggle-rubric-section': (el) => toggleRubricSection(el.dataset.arg),
  'save-run-score': () => saveRunScore(),
  'start-timer': (el) => startTimer(el.dataset.arg),
  'reset-timer': (el) => resetTimer(el.dataset.arg),
  'toggle-scoring-mission': (el) => toggleScoringMission(Number(el.dataset.id)),
  'delete-sticky': (el) => deleteSticky(Number(el.dataset.id)),
  'toggle-checklist': (el) => toggleChecklist(Number(el.dataset.id)),
  'remove-checklist-item': (el) => removeChecklistItem(Number(el.dataset.id)),

  // My tasks / Team
  'switch-mytasks-tab': (el) => switchMyTasksTab(el.dataset.arg),
  'show-add-member-modal': () => showAddMemberModal(),
  'add-checklist-item': () => addChecklistItem(),
  'open-private-chat': (el) => openPrivateChat(el.dataset.id, el.dataset.name),
  'show-add-member-task-modal': (el) => showAddMemberTaskModal(el.dataset.id),
  'admin-change-name': (el) => adminChangeName(el.dataset.id),
  'remove-member': (el) => removeMember(el.dataset.id),
  'toggle-member-task': (el) => toggleMemberTask(Number(el.dataset.id)),
  'delete-member-task': (el) => deleteMemberTask(Number(el.dataset.id)),

  // Chat
  'switch-chat-tab': (el) => switchChatTab(el.dataset.arg),
  'send-chat-message': () => sendChatMessage(),
  'open-modal': (el) => openModal(el.dataset.arg),
  'cast-vote': (el) => castVote(el.dataset.id, Number(el.dataset.option)),
  'close-poll': (el) => closePoll(el.dataset.id),
  'delete-announcement': (el) => deleteAnnouncement(el.dataset.id),

  // Archive
  'open-new-season-modal': () => openNewSeasonModal(),
  'export-data': (el) => exportData(el.dataset.arg),
  'close-archive-view': () => closeArchiveView(),
  'export-archived-season': () => exportArchivedSeason(),
  'view-archived-season': (el) => viewArchivedSeason(Number(el.dataset.index)),

  // Settings
  'handle-logo-upload': (el, e) => handleLogoUpload(e, el.dataset.arg),
  'save-team-settings': () => saveTeamSettings(),
  'change-my-name': () => changeMyName(),
  'start-tour': () => startTour(),
  'change-pin': () => changePin(),
  'setup-biometric': () => setupBiometric(),
  'copy-settings-code': (el) => copySettingsCode(el.dataset.arg),
  'regenerate-codes': () => regenerateCodes(),
  'save-competition-date': () => saveCompetitionDate(),
  'leave-team': () => leaveTeam(),
  'delete-my-account': () => deleteMyAccount(),
  'reset-team-data': () => resetTeamData(),
  'delete-team': () => deleteTeam(),

  // Strategy board
  'sb-set-tool': (el) => sbSetTool(el.dataset.arg),
  'sb-set-color': (el) => sbSetColor(el.dataset.arg),
  'sb-set-color-custom': (el) => sbSetColor(el.value),
  'sb-set-width': (el) => sbSetWidth(Number(el.dataset.arg)),
  'sb-undo': () => sbUndo(),
  'sb-clear-drawing': () => sbClearDrawing(),
  'sb-upload-background': (el, e) => sbUploadBackground(e),
  'sb-clear-background': () => sbClearBackground(),
  'sb-save-image': () => sbSaveImage(),

  // Gallery
  'add-team-photo': (el, e) => addTeamPhoto(e),
  'delete-improvement': (el) => deleteImprovement(Number(el.dataset.id)),
  'view-team-photo': (el) => viewTeamPhoto(Number(el.dataset.id)),
  'delete-team-photo': (el) => deleteTeamPhoto(Number(el.dataset.id)),

  // Links
  'show-add-link-modal': () => showAddLinkModal(),
  'filter-links': (el) => filterLinks(el.dataset.arg),
  'delete-link': (el) => deleteLink(Number(el.dataset.id)),

  // Judging
  'switch-judging-tab': (el) => switchJudgingTab(el.dataset.arg),
  'add-judging-question': () => addJudgingQuestion(),
  'edit-judging-answer': (el) => editJudgingAnswer(Number(el.dataset.id)),
  'delete-judging-question': (el) => deleteJudgingQuestion(Number(el.dataset.id)),
  'upload-judging-doc': (el, e) => uploadJudgingDoc(e),
  'open-judging-doc': () => openJudgingDoc(),
  'delete-judging-doc': () => deleteJudgingDoc(),

  // Modals (generic)
  'close-modal': (el) => closeModal(el.dataset.arg),
  'save-log': () => saveLog(),
  'save-member': () => saveMember(),
  'save-improvement': () => saveImprovement(),
  'save-innov-step': () => saveInnovStep(),
  'save-interview': () => saveInterview(),
  'save-finding': () => saveFinding(),
  'save-sticky': () => saveSticky(),
  'save-rubric': () => saveRubric(),
  'create-new-season': () => createNewSeason(),
  'save-member-task': () => saveMemberTask(),
  'toggle-select-all': () => toggleSelectAll(),
  'create-video-from-selected': () => createVideoFromSelected(),
  'create-poll': () => createPoll(),
  'send-announcement': () => sendAnnouncement(),
  'save-link': () => saveLink(),

  // Guided tour
  'tour-back': () => _tourBack(),
  'tour-advance': () => _tourAdvance(),
};

document.addEventListener('click', (e) => {
  const el = e.target.closest('[data-action]');
  if (!el) return;
  const fn = ACTIONS[el.dataset.action];
  if (fn) fn(el, e);
});

document.addEventListener('change', (e) => {
  const el = e.target.closest('[data-onchange]');
  if (!el) return;
  const fn = ACTIONS[el.dataset.onchange];
  if (fn) fn(el, e);
});

document.addEventListener('input', (e) => {
  const el = e.target.closest('[data-oninput]');
  if (!el) return;
  const fn = ACTIONS[el.dataset.oninput];
  if (fn) fn(el, e);
});

// One-off bindings that don't fit the generic data-action pattern.
document.addEventListener('DOMContentLoaded', () => {
  const codeInput = document.getElementById('join-code-input');
  if (codeInput) {
    codeInput.addEventListener('input', () => {
      codeInput.value = codeInput.value.toUpperCase().replace(/[^A-Z0-9-]/g, '');
    });
  }
  const chatInput = document.getElementById('chat-input');
  if (chatInput) {
    chatInput.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') sendChatMessage();
    });
  }
});
