# Requirements Document

## Introduction

This feature delivers the complete browsing flow that follows map load in the Memo Flutter
mobile app (`apps/mobile`): a chronological Timeline, a rich Pin Detail view, and a Media
Viewer for images and audio. The backend (`apps/api`, NestJS) already exposes the required
endpoints, so this work is scoped to the mobile feature. The implementation fleshes out
existing skeleton files (`timeline_screen.dart`, `pin_detail_screen.dart`, the `media/`
directory, repositories, mock repositories, and DTOs) end-to-end.

The work must respect repository conventions: the UI layer must depend on
repositories/providers (Riverpod) and never call Dio or HTTP directly; media binaries are
never stored in the backend or database (the backend signs presigned read URLs over object
keys); offline mode must keep text and coordinates visible while media may be pending or
uncached; user-facing strings must be localizable (en + vi); and the map provider stays
behind project-owned ports in `apps/mobile/lib/map`.

This document covers the Jira Sprint 2 epic "Timeline, Pin Detail and Media Viewer
end-to-end" and its subtasks SCRUM-74, SCRUM-61, SCRUM-62, and SCRUM-75.

## Glossary

- **Timeline_View**: The mobile screen (`timeline_screen.dart`) that lists pins of the active
  map ordered by memory date.
- **Pin_Detail_View**: The mobile screen (`pin_detail_screen.dart`) that shows a single pin's
  title, note, memory date, coordinates, media, and actions.
- **Media_Viewer**: The mobile components that display a pin's image media full-screen and play
  a pin's audio media.
- **Image_Viewer**: The Media_Viewer component that displays image media full-screen.
- **Audio_Player**: The Media_Viewer component that controls playback of audio media.
- **Timeline_Repository**: The mobile repository interface (`timeline_repository.dart`)
  returning a `TimelinePageDto` for a given map and sort order.
- **Pin_Repository**: The mobile repository interface (`pin_repository.dart`) returning a
  `PinDto` for a given pin id.
- **Media_Repository**: The mobile repository interface (`media_repository.dart`) responsible
  for presigned uploads, media registration, and authorized read-URL retrieval.
- **Pin**: A `PinDto` with id, mapId, title, note, optional memoryDate, lat, lng, media list,
  createdAt, and updatedAt.
- **Memory_Date**: The optional `memoryDate` field of a Pin used as the primary Timeline sort
  key.
- **Pin_Media**: A `PinMediaDto` describing one media item with id, mediaType (image, text,
  audio), objectKey, mimeType, sizeBytes, and an optional read url.
- **Authorized_Read_URL**: A presigned, time-limited object-storage URL obtained for a media
  item through `GET /api/v1/media/:mediaId/presign`.
- **Sort_Order**: The Timeline ordering selection, either `newest` (descending memory date) or
  `oldest` (ascending memory date).
- **Offline_Mode**: The application state in which media cannot be loaded from the network and
  text/coordinate content must remain visible.
- **Media_Placeholder**: A visual stand-in shown when a media item is pending, uncached, or
  cannot be loaded.
- **App_Shell**: The mobile navigation shell, including the bottom navigation bar and
  `go_router` routes defined in `router.dart`.
- **Active_Map**: The map whose pins are currently browsed, resolved through
  `mapRepositoryProvider`.

## Requirements

### Requirement 1: Load and display the Timeline

**User Story:** As a user, I want to see my memories listed chronologically, so that I can
browse my pins by when they happened.

#### Acceptance Criteria

1. WHEN the Timeline_View is opened, THE Timeline_View SHALL request timeline items for the
   Active_Map through the Timeline_Repository provider without calling Dio or HTTP directly.
2. WHILE the timeline request is in progress, THE Timeline_View SHALL display a loading
   indicator.
3. WHEN the Timeline_Repository returns a TimelinePageDto, THE Timeline_View SHALL render one
   list entry for each Pin in the returned items.
4. WHERE a Pin has a Memory_Date, THE Timeline_View SHALL display that Pin's Memory_Date in the
   localized date format.
5. THE Timeline_View SHALL display each Pin's title for every rendered list entry.
6. IF the Timeline_Repository returns zero items AND no timeline entries are rendered, THEN THE
   Timeline_View SHALL display a localized empty-state message instead of placeholder content.
7. IF the timeline request fails, THEN THE Timeline_View SHALL display a localized error
   message and a retry control.

### Requirement 2: Sort the Timeline by newest or oldest

**User Story:** As a user, I want to toggle between newest-first and oldest-first, so that I
can browse my memories in either chronological direction.

#### Acceptance Criteria

1. THE Timeline_View SHALL display a Sort_Order toggle with a `newest` option and an `oldest`
   option.
2. WHEN the Timeline_View loads for the first time, THE Timeline_View SHALL request the
   timeline with Sort_Order set to `newest`.
3. WHEN the user selects the `oldest` option, THE Timeline_View SHALL request the timeline with
   `order` set to `asc` through the Timeline_Repository.
4. WHEN the user selects the `newest` option, THE Timeline_View SHALL request the timeline with
   `order` set to `desc` through the Timeline_Repository.
5. WHEN the user changes the Sort_Order, THE Timeline_View SHALL display the same set of Pins
   that were present before the change, reordered according to the selected Sort_Order.
6. WHEN the Sort_Order is `newest`, THE Timeline_View SHALL order Pins that have a Memory_Date
   by descending Memory_Date.
7. WHEN the Sort_Order is `oldest`, THE Timeline_View SHALL order Pins that have a Memory_Date
   by ascending Memory_Date.
8. WHEN the user changes the Sort_Order, THE Timeline_View SHALL synchronize the displayed
   ordering with the selected Sort_Order before the next user interaction.

### Requirement 3: Handle Pins with a missing Memory_Date

**User Story:** As a user, I want memories without a recorded date to still appear, so that no
pin disappears from my timeline.

#### Acceptance Criteria

1. WHERE a Pin has no Memory_Date, THE Timeline_View SHALL include that Pin in the rendered
   list for both Sort_Order values.
2. WHEN the timeline is rendered for any Sort_Order, THE Timeline_View SHALL place Pins without
   a Memory_Date after all Pins that have a Memory_Date.
3. WHERE a Pin has no Memory_Date, THE Timeline_View SHALL display a localized "date unknown"
   label for that Pin, falling back to the English label if the localized string is
   unavailable.
4. WHEN the Sort_Order changes between `newest` and `oldest`, THE Timeline_View SHALL retain
   every Pin without a Memory_Date in the rendered list.

### Requirement 4: Open Pin Detail from a Timeline entry

**User Story:** As a user, I want to tap a timeline entry to open its details, so that I can
read and act on that specific memory.

#### Acceptance Criteria

1. WHEN the user selects a Timeline_View entry, THE App_Shell SHALL navigate to the Pin_Detail_View
   for the Pin id of the selected entry.
2. WHEN the Pin_Detail_View is opened for a Pin id, THE Pin_Detail_View SHALL request that Pin
   through the Pin_Repository provider.
3. WHEN the Pin_Repository returns the requested Pin, THE Pin_Detail_View SHALL display the Pin
   whose id matches the requested Pin id.
4. IF the Pin_Repository request for the Pin id fails, THEN THE Pin_Detail_View SHALL display a
   localized error message.

### Requirement 5: Display Pin Detail content

**User Story:** As a user, I want to see a memory's title, note, date, and coordinates, so that
I can revisit the full context of that memory.

#### Acceptance Criteria

1. WHEN the Pin_Detail_View renders a Pin, THE Pin_Detail_View SHALL display the Pin's title.
2. WHERE a Pin has a non-empty note, THE Pin_Detail_View SHALL display the Pin's note.
3. WHERE a Pin has a Memory_Date, THE Pin_Detail_View SHALL display the Memory_Date in the
   localized date format.
4. WHERE a Pin has no Memory_Date, THE Pin_Detail_View SHALL display a localized "date unknown"
   label, falling back to the English label if the localized string is unavailable.
5. WHERE a Pin has valid latitude and longitude values, THE Pin_Detail_View SHALL display those
   latitude and longitude values.
6. IF a Pin's latitude or longitude value is unavailable, THEN THE Pin_Detail_View SHALL display
   a localized "coordinates unavailable" label instead of coordinate values.
7. WHEN the Pin_Detail_View renders a Pin, THE Pin_Detail_View SHALL display content derived
   only from the Pin returned by the Pin_Repository.

### Requirement 6: Pin Detail navigation and actions

**User Story:** As a user, I want to jump to a memory's map location and reach edit, delete,
and share actions, so that I can act on a memory from its detail view.

#### Acceptance Criteria

1. WHEN the user selects the "view on map" action in the Pin_Detail_View, THE App_Shell SHALL
   navigate to the map route with the selected Pin's latitude and longitude.
2. THE Pin_Detail_View SHALL display an edit action that navigates to the pin editor route for
   the current Pin id.
3. THE Pin_Detail_View SHALL display a delete action entry point for the current Pin.
4. THE Pin_Detail_View SHALL display a share action entry point for the current Pin.
5. WHEN the user navigates from a Timeline_View entry to the Pin_Detail_View and then back,
   THE App_Shell SHALL return to the Timeline_View.

### Requirement 7: Retrieve authorized media read URLs

**User Story:** As a user, I want attached media to load securely, so that only authorized
media is shown without the app handling raw storage credentials.

#### Acceptance Criteria

1. THE Media_Repository SHALL expose an operation that returns an Authorized_Read_URL for a
   given media id.
2. WHEN a media item must be displayed or played, THE Pin_Detail_View SHALL obtain the media's
   Authorized_Read_URL through the Media_Repository provider rather than constructing a URL
   directly.
3. WHEN the Media_Repository returns an Authorized_Read_URL for a media id, THE Media_Viewer
   SHALL load the media content from that Authorized_Read_URL.
4. IF the Authorized_Read_URL request for a media id fails, THEN THE Pin_Detail_View SHALL
   display a Media_Placeholder for that media item.
5. THE Pin_Detail_View SHALL NOT call Dio or backend endpoint paths directly when retrieving
   media read URLs.

### Requirement 8: View image media

**User Story:** As a user, I want to open attached photos full-screen, so that I can look at my
memory images closely.

#### Acceptance Criteria

1. WHERE a Pin has at least one image-type Pin_Media item, THE Pin_Detail_View SHALL display a
   selectable thumbnail for each image-type Pin_Media item.
2. WHEN the user selects an image thumbnail, THE Image_Viewer SHALL open and display the
   selected image loaded from its Authorized_Read_URL.
3. WHILE the Image_Viewer is open AND an image's Authorized_Read_URL is being retrieved or the
   image is loading, THE Image_Viewer SHALL display a loading indicator for that image.
4. IF an image fails to load from its Authorized_Read_URL, THEN THE Image_Viewer SHALL display
   a Media_Placeholder together with a localized retry control for that image.
5. WHEN the user activates the retry control for an image, THE Image_Viewer SHALL request the
   image's Authorized_Read_URL again and attempt to load the image.
6. WHEN the user dismisses the Image_Viewer, THE App_Shell SHALL return to the Pin_Detail_View.

### Requirement 9: Play audio media

**User Story:** As a user, I want to play attached voice recordings, so that I can listen to my
audio memories.

#### Acceptance Criteria

1. WHERE a Pin has at least one audio-type Pin_Media item, THE Pin_Detail_View SHALL display an
   Audio_Player control for that Pin_Media item.
2. WHEN the user activates the play control, THE Audio_Player SHALL play the audio loaded from
   its Authorized_Read_URL.
3. WHILE audio is playing, THE Audio_Player SHALL display a pause control.
4. WHEN the user activates the pause control, THE Audio_Player SHALL pause audio playback.
5. IF the audio fails to load from its Authorized_Read_URL, THEN THE Audio_Player SHALL hide
   the play and pause controls and display a Media_Placeholder indicating the audio is
   unavailable.

### Requirement 10: Offline and unavailable media placeholders

**User Story:** As a user, I want to still read my notes and coordinates when media cannot
load, so that offline memories remain useful.

#### Acceptance Criteria

1. WHILE the application is in Offline_Mode, THE Pin_Detail_View SHALL display the Pin's title,
   note, Memory_Date label, and coordinates.
2. WHILE the application is in Offline_Mode, THE Pin_Detail_View SHALL display a Media_Placeholder
   for each Pin_Media item that cannot be loaded.
3. WHERE a Pin_Media item is pending or uncached, THE Pin_Detail_View SHALL display a
   Media_Placeholder for that Pin_Media item.
4. WHILE the application is in Offline_Mode, THE Timeline_View SHALL display each Pin's title
   and Memory_Date label.
5. WHEN media becomes loadable after being shown as a Media_Placeholder, THE Media_Viewer SHALL
   load the media content from its Authorized_Read_URL.

### Requirement 11: Mock-mode support for feature development

**User Story:** As a developer, I want the timeline, pin detail, and media flows to work
against fake repositories, so that I can build and test the feature without the backend.

#### Acceptance Criteria

1. WHERE the `USE_MOCK_DATA` flag is true, THE Timeline_View SHALL load timeline items through
   the fake Timeline_Repository.
2. WHERE the `USE_MOCK_DATA` flag is true, THE Pin_Detail_View SHALL load the Pin through the
   fake Pin_Repository.
3. WHERE the `USE_MOCK_DATA` flag is true, THE Media_Repository SHALL return an
   Authorized_Read_URL for a media id from the fake Media_Repository.
4. THE fake Media_Repository SHALL implement the same Authorized_Read_URL operation defined on
   the Media_Repository interface.
5. IF a fake repository request fails WHILE the `USE_MOCK_DATA` flag is true, THEN THE
   requesting view SHALL display a localized error message rather than falling back to real
   repositories.

### Requirement 12: Localized user-facing strings

**User Story:** As a user, I want the timeline, detail, and media screens in my language, so
that the app is usable in English and Vietnamese.

#### Acceptance Criteria

1. THE Timeline_View SHALL source its user-facing labels, including the Sort_Order options and
   empty-state message, from the localization resources.
2. THE Pin_Detail_View SHALL source its user-facing labels, including the action labels and the
   "date unknown" label, from the localization resources.
3. THE Media_Viewer SHALL source its user-facing labels, including Media_Placeholder text, from
   the localization resources.
4. THE localization resources SHALL define each new user-facing string in both the English and
   Vietnamese resource files.

### Requirement 13: Automated test coverage

**User Story:** As a developer, I want widget and unit tests for these flows, so that timeline
state, detail navigation, and media placeholders stay correct.

#### Acceptance Criteria

1. THE mobile test suite SHALL include a widget test verifying that the Timeline_View renders
   all Pins returned by the Timeline_Repository, including Pins without a Memory_Date.
2. THE mobile test suite SHALL include a test verifying that changing the Sort_Order reorders
   the Timeline_View without removing any Pin.
3. THE mobile test suite SHALL include a widget test verifying that selecting a Timeline_View
   entry navigates to the Pin_Detail_View for the matching Pin id.
4. THE mobile test suite SHALL include a test verifying that the Pin_Detail_View displays a
   Media_Placeholder when an Authorized_Read_URL cannot be retrieved or media fails to load.
5. THE mobile test suite SHALL include a test verifying that the Pin_Detail_View displays the
   Pin's title, note, and coordinates when media is unavailable.
