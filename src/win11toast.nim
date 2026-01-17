## Win11Toast - Windows 10/11 Toast Notifications for Nim
## 
## A pure Nim library for creating toast notifications on Windows 10/11
## using the Windows Runtime (WinRT) APIs.
## 
## Based on the Python win11toast library and valinet's plain C implementation.
## 
## Copyright (c) 2025
## MIT License

import std/[asyncdispatch, tables, strutils, strformat, times, options]

when defined(windows):
    import winim/lean
    import winim/winstr

    # ============================================================================
    # WinRT Base Types and Helpers
    # ============================================================================

    type
        HSTRING       * = pointer
        HSTRING_HEADER* = object
            reserved* : pointer
            reserved2*: array[24, byte]  # 24 bytes for x64, 20 for x86

        RO_INIT_TYPE* {.size: sizeof(int32).} = enum
            RO_INIT_SINGLETHREADED = 0
            RO_INIT_MULTITHREADED  = 1

        TrustLevel* {.size: sizeof(int32).} = enum
            BaseTrust    = 0
            PartialTrust = 1
            FullTrust    = 2

    # ============================================================================
    # COM/WinRT Interface Definitions
    # ============================================================================

    type
        # IInspectable - Base WinRT interface
        IInspectableVtbl* = object
            # IUnknown methods
            QueryInterface* : proc(self: pointer, riid: ptr GUID, ppvObject: ptr pointer): HRESULT {.stdcall.}
            AddRef*         : proc(self: pointer): ULONG {.stdcall.}
            Release*        : proc(self: pointer): ULONG {.stdcall.}
            # IInspectable methods
            GetIids*              : proc(self: pointer, iidCount: ptr ULONG, iids: ptr ptr GUID): HRESULT {.stdcall.}
            GetRuntimeClassName*  : proc(self: pointer, className: ptr HSTRING): HRESULT {.stdcall.}
            GetTrustLevel*        : proc(self: pointer, trustLevel: ptr TrustLevel): HRESULT {.stdcall.}

        IInspectable* = object
            lpVtbl*: ptr IInspectableVtbl

        # IXmlDocument interface
        IXmlDocumentVtbl* = object
            # IUnknown
            QueryInterface*       : proc(self: pointer, riid: ptr GUID, ppvObject: ptr pointer): HRESULT {.stdcall.}
            AddRef*               : proc(self: pointer): ULONG {.stdcall.}
            Release*              : proc(self: pointer): ULONG {.stdcall.}
            # IInspectable
            GetIids*              : proc(self: pointer, iidCount: ptr ULONG, iids: ptr ptr GUID): HRESULT {.stdcall.}
            GetRuntimeClassName*  : proc(self: pointer, className: ptr HSTRING): HRESULT {.stdcall.}
            GetTrustLevel*        : proc(self: pointer, trustLevel: ptr TrustLevel): HRESULT {.stdcall.}
            # IXmlDocument methods (we don't use most of these, but need correct vtable layout)
            get_Doctype*          : proc(self: pointer, value: ptr pointer): HRESULT {.stdcall.}
            get_Implementation*   : proc(self: pointer, value: ptr pointer): HRESULT {.stdcall.}
            get_DocumentElement*  : proc(self: pointer, value: ptr pointer): HRESULT {.stdcall.}
            CreateElement*        : proc(self: pointer, tagName: HSTRING, newElement: ptr pointer): HRESULT {.stdcall.}
            CreateDocumentFragment*  : proc(self: pointer, newDocumentFragment: ptr pointer): HRESULT {.stdcall.}
            CreateTextNode*       : proc(self: pointer, data: HSTRING, newTextNode: ptr pointer): HRESULT {.stdcall.}
            CreateComment*        : proc(self: pointer, data: HSTRING, newComment: ptr pointer): HRESULT {.stdcall.}
            CreateProcessingInstruction*: proc(self: pointer, target: HSTRING, data: HSTRING, newProcessingInstruction: ptr pointer): HRESULT {.stdcall.}
            CreateAttribute*      : proc(self: pointer, name: HSTRING, newAttribute: ptr pointer): HRESULT {.stdcall.}
            CreateEntityReference*: proc(self: pointer, name: HSTRING, newEntityReference: ptr pointer): HRESULT {.stdcall.}
            GetElementsByTagName* : proc(self: pointer, tagName: HSTRING, elements: ptr pointer): HRESULT {.stdcall.}
            CreateCDataSection*   : proc(self: pointer, data: HSTRING, newCDataSection: ptr pointer): HRESULT {.stdcall.}
            get_DocumentUri*      : proc(self: pointer, value: ptr HSTRING): HRESULT {.stdcall.}
            CreateAttributeNS*    : proc(self: pointer, namespaceUri: pointer, qualifiedName: HSTRING, newAttribute: ptr pointer): HRESULT {.stdcall.}
            CreateElementNS*      : proc(self: pointer, namespaceUri: pointer, qualifiedName: HSTRING, newElement: ptr pointer): HRESULT {.stdcall.}
            GetElementById*       : proc(self: pointer, elementId: HSTRING, element: ptr pointer): HRESULT {.stdcall.}
            ImportNode*           : proc(self: pointer, node: pointer, deep: bool, newNode: ptr pointer): HRESULT {.stdcall.}

        IXmlDocument* = object
            lpVtbl*: ptr IXmlDocumentVtbl

        # IXmlDocumentIO interface
        IXmlDocumentIOVtbl* = object
            # IUnknown
            QueryInterface*       : proc(self: pointer, riid: ptr GUID, ppvObject: ptr pointer): HRESULT {.stdcall.}
            AddRef*               : proc(self: pointer): ULONG {.stdcall.}
            Release*              : proc(self: pointer): ULONG {.stdcall.}
            # IInspectable
            GetIids*              : proc(self: pointer, iidCount: ptr ULONG, iids: ptr ptr GUID): HRESULT {.stdcall.}
            GetRuntimeClassName*  : proc(self: pointer, className: ptr HSTRING): HRESULT {.stdcall.}
            GetTrustLevel*        : proc(self: pointer, trustLevel: ptr TrustLevel): HRESULT {.stdcall.}
            # IXmlDocumentIO
            LoadXml*              : proc(self: pointer, xml: HSTRING): HRESULT {.stdcall.}
            LoadXmlWithSettings*  : proc(self: pointer, xml: HSTRING, loadSettings: pointer): HRESULT {.stdcall.}
            SaveToFileAsync*      : proc(self: pointer, file: pointer, asyncInfo: ptr pointer): HRESULT {.stdcall.}

        IXmlDocumentIO* = object
            lpVtbl*: ptr IXmlDocumentIOVtbl

        # IToastNotificationManagerStatics interface
        IToastNotificationManagerStaticsVtbl* = object
            # IUnknown
            QueryInterface*       : proc(self: pointer, riid: ptr GUID, ppvObject: ptr pointer): HRESULT {.stdcall.}
            AddRef*               : proc(self: pointer): ULONG {.stdcall.}
            Release*              : proc(self: pointer): ULONG {.stdcall.}
            # IInspectable
            GetIids*              : proc(self: pointer, iidCount: ptr ULONG, iids: ptr ptr GUID): HRESULT {.stdcall.}
            GetRuntimeClassName*  : proc(self: pointer, className: ptr HSTRING): HRESULT {.stdcall.}
            GetTrustLevel*        : proc(self: pointer, trustLevel: ptr TrustLevel): HRESULT {.stdcall.}
            # IToastNotificationManagerStatics
            CreateToastNotifier*      : proc(self: pointer, result: ptr pointer): HRESULT {.stdcall.}
            CreateToastNotifierWithId*: proc(self: pointer, applicationId: HSTRING, result: ptr pointer): HRESULT {.stdcall.}
            GetTemplateContent*       : proc(self: pointer, templateType: int32, content: ptr pointer): HRESULT {.stdcall.}

        IToastNotificationManagerStatics* = object
            lpVtbl*: ptr IToastNotificationManagerStaticsVtbl

        # IToastNotificationFactory interface
        IToastNotificationFactoryVtbl* = object
            # IUnknown
            QueryInterface*       : proc(self: pointer, riid: ptr GUID, ppvObject: ptr pointer): HRESULT {.stdcall.}
            AddRef*               : proc(self: pointer): ULONG {.stdcall.}
            Release*              : proc(self: pointer): ULONG {.stdcall.}
            # IInspectable
            GetIids*              : proc(self: pointer, iidCount: ptr ULONG, iids: ptr ptr GUID): HRESULT {.stdcall.}
            GetRuntimeClassName*  : proc(self: pointer, className: ptr HSTRING): HRESULT {.stdcall.}
            GetTrustLevel*        : proc(self: pointer, trustLevel: ptr TrustLevel): HRESULT {.stdcall.}
            # IToastNotificationFactory
            CreateToastNotification*: proc(self: pointer, content: pointer, result: ptr pointer): HRESULT {.stdcall.}

        IToastNotificationFactory* = object
            lpVtbl*: ptr IToastNotificationFactoryVtbl

        # IToastNotifier interface
        IToastNotifierVtbl* = object
            # IUnknown
            QueryInterface*       : proc(self: pointer, riid: ptr GUID, ppvObject: ptr pointer): HRESULT {.stdcall.}
            AddRef*               : proc(self: pointer): ULONG {.stdcall.}
            Release*              : proc(self: pointer): ULONG {.stdcall.}
            # IInspectable
            GetIids*              : proc(self: pointer, iidCount: ptr ULONG, iids: ptr ptr GUID): HRESULT {.stdcall.}
            GetRuntimeClassName*  : proc(self: pointer, className: ptr HSTRING): HRESULT {.stdcall.}
            GetTrustLevel*        : proc(self: pointer, trustLevel: ptr TrustLevel): HRESULT {.stdcall.}
            # IToastNotifier
            Show*                 : proc(self: pointer, notification: pointer): HRESULT {.stdcall.}
            Hide*                 : proc(self: pointer, notification: pointer): HRESULT {.stdcall.}
            get_Setting*          : proc(self: pointer, value: ptr int32): HRESULT {.stdcall.}
            AddToSchedule*        : proc(self: pointer, scheduledToast: pointer): HRESULT {.stdcall.}
            RemoveFromSchedule*   : proc(self: pointer, scheduledToast: pointer): HRESULT {.stdcall.}
            GetScheduledToastNotifications*: proc(self: pointer, result: ptr pointer): HRESULT {.stdcall.}

        IToastNotifier* = object
            lpVtbl*: ptr IToastNotifierVtbl

        # IToastNotification interface
        IToastNotificationVtbl* = object
            # IUnknown
            QueryInterface*       : proc(self: pointer, riid: ptr GUID, ppvObject: ptr pointer): HRESULT {.stdcall.}
            AddRef*               : proc(self: pointer): ULONG {.stdcall.}
            Release*              : proc(self: pointer): ULONG {.stdcall.}
            # IInspectable
            GetIids*              : proc(self: pointer, iidCount: ptr ULONG, iids: ptr ptr GUID): HRESULT {.stdcall.}
            GetRuntimeClassName*  : proc(self: pointer, className: ptr HSTRING): HRESULT {.stdcall.}
            GetTrustLevel*        : proc(self: pointer, trustLevel: ptr TrustLevel): HRESULT {.stdcall.}
            # IToastNotification
            get_Content*          : proc(self: pointer, value: ptr pointer): HRESULT {.stdcall.}
            put_ExpirationTime*   : proc(self: pointer, value: pointer): HRESULT {.stdcall.}
            get_ExpirationTime*   : proc(self: pointer, value: ptr pointer): HRESULT {.stdcall.}
            add_Dismissed*        : proc(self: pointer, handler: pointer, token: ptr int64): HRESULT {.stdcall.}
            remove_Dismissed*     : proc(self: pointer, token: int64): HRESULT {.stdcall.}
            add_Activated*        : proc(self: pointer, handler: pointer, token: ptr int64): HRESULT {.stdcall.}
            remove_Activated*     : proc(self: pointer, token: int64): HRESULT {.stdcall.}
            add_Failed*           : proc(self: pointer, handler: pointer, token: ptr int64): HRESULT {.stdcall.}
            remove_Failed*        : proc(self: pointer, token: int64): HRESULT {.stdcall.}
            put_Tag*              : proc(self: pointer, value: HSTRING): HRESULT {.stdcall.}
            get_Tag*              : proc(self: pointer, value: ptr HSTRING): HRESULT {.stdcall.}
            put_Group*            : proc(self: pointer, value: HSTRING): HRESULT {.stdcall.}
            get_Group*            : proc(self: pointer, value: ptr HSTRING): HRESULT {.stdcall.}
            put_SuppressPopup*    : proc(self: pointer, value: bool): HRESULT {.stdcall.}
            get_SuppressPopup*    : proc(self: pointer, value: ptr bool): HRESULT {.stdcall.}

        IToastNotification* = object
            lpVtbl*: ptr IToastNotificationVtbl

        # IToastNotification2 interface (for Data property)
        IToastNotification2Vtbl* = object
            # IUnknown
            QueryInterface*       : proc(self: pointer, riid: ptr GUID, ppvObject: ptr pointer): HRESULT {.stdcall.}
            AddRef*               : proc(self: pointer): ULONG {.stdcall.}
            Release*              : proc(self: pointer): ULONG {.stdcall.}
            # IInspectable
            GetIids*              : proc(self: pointer, iidCount: ptr ULONG, iids: ptr ptr GUID): HRESULT {.stdcall.}
            GetRuntimeClassName*  : proc(self: pointer, className: ptr HSTRING): HRESULT {.stdcall.}
            GetTrustLevel*        : proc(self: pointer, trustLevel: ptr TrustLevel): HRESULT {.stdcall.}
            # IToastNotification2
            put_Tag*              : proc(self: pointer, value: HSTRING): HRESULT {.stdcall.}
            get_Tag*              : proc(self: pointer, value: ptr HSTRING): HRESULT {.stdcall.}
            put_Group*            : proc(self: pointer, value: HSTRING): HRESULT {.stdcall.}
            get_Group*            : proc(self: pointer, value: ptr HSTRING): HRESULT {.stdcall.}
            put_SuppressPopup*    : proc(self: pointer, value: bool): HRESULT {.stdcall.}
            get_SuppressPopup*    : proc(self: pointer, value: ptr bool): HRESULT {.stdcall.}

        IToastNotification2* = object
            lpVtbl*: ptr IToastNotification2Vtbl

    # ============================================================================
    # GUIDs
    # ============================================================================

    let
        # IXmlDocument: f7f3a506-1e87-42d6-bcfb-b8c809fa5494
        IID_IXmlDocument* = GUID(
            Data1: cast[DWORD](0xf7f3a506'u32)
            ,Data2: cast[WORD](0x1e87'u16)
            ,Data3: cast[WORD](0x42d6'u16)
            ,Data4: [0xbc'u8, 0xfb'u8, 0xb8'u8, 0xc8'u8, 0x09'u8, 0xfa'u8, 0x54'u8, 0x94'u8]
        )

        # IXmlDocumentIO: 6cd0e74e-ee65-4489-9ebf-ca43e87ba637
        IID_IXmlDocumentIO* = GUID(
            Data1: cast[DWORD](0x6cd0e74e'u32)
            ,Data2: cast[WORD](0xee65'u16)
            ,Data3: cast[WORD](0x4489'u16)
            ,Data4: [0x9e'u8, 0xbf'u8, 0xca'u8, 0x43'u8, 0xe8'u8, 0x7b'u8, 0xa6'u8, 0x37'u8]
        )

        # IToastNotificationManagerStatics: 50ac103f-d235-4598-bbef-98fe4d1a3ad4
        IID_IToastNotificationManagerStatics* = GUID(
            Data1: cast[DWORD](0x50ac103f'u32)
            ,Data2: cast[WORD](0xd235'u16)
            ,Data3: cast[WORD](0x4598'u16)
            ,Data4: [0xbb'u8, 0xef'u8, 0x98'u8, 0xfe'u8, 0x4d'u8, 0x1a'u8, 0x3a'u8, 0xd4'u8]
        )

        # IToastNotificationFactory: 04124b20-82c6-4229-b109-fd9ed4662b53
        IID_IToastNotificationFactory* = GUID(
            Data1: cast[DWORD](0x04124b20'u32)
            ,Data2: cast[WORD](0x82c6'u16)
            ,Data3: cast[WORD](0x4229'u16)
            ,Data4: [0xb1'u8, 0x09'u8, 0xfd'u8, 0x9e'u8, 0xd4'u8, 0x66'u8, 0x2b'u8, 0x53'u8]
        )

        # IToastNotifier: 75927b93-03f3-41ec-91d3-6e5bac1b38e7
        IID_IToastNotifier* = GUID(
            Data1: cast[DWORD](0x75927b93'u32)
            ,Data2: cast[WORD](0x03f3'u16)
            ,Data3: cast[WORD](0x41ec'u16)
            ,Data4: [0x91'u8, 0xd3'u8, 0x6e'u8, 0x5b'u8, 0xac'u8, 0x1b'u8, 0x38'u8, 0xe7'u8]
        )

        # IToastNotification: 997e2675-059e-4e60-8b06-1760917c8b80
        IID_IToastNotification* = GUID(
            Data1: cast[DWORD](0x997e2675'u32)
            ,Data2: cast[WORD](0x059e'u16)
            ,Data3: cast[WORD](0x4e60'u16)
            ,Data4: [0x8b'u8, 0x06'u8, 0x17'u8, 0x60'u8, 0x91'u8, 0x7c'u8, 0x8b'u8, 0x80'u8]
        )

        # IToastNotification2: 9dfb9fd1-143a-490e-90bf-b9fba7132de7
        IID_IToastNotification2* = GUID(
            Data1: cast[DWORD](0x9dfb9fd1'u32)
            ,Data2: cast[WORD](0x143a'u16)
            ,Data3: cast[WORD](0x490e'u16)
            ,Data4: [0x90'u8, 0xbf'u8, 0xb9'u8, 0xfb'u8, 0xa7'u8, 0x13'u8, 0x2d'u8, 0xe7'u8]
        )

    # ============================================================================
    # WinRT Runtime Class Names
    # ============================================================================

    const
        RuntimeClass_XmlDocument*                = "Windows.Data.Xml.Dom.XmlDocument"
        RuntimeClass_ToastNotificationManager*   = "Windows.UI.Notifications.ToastNotificationManager"
        RuntimeClass_ToastNotification*          = "Windows.UI.Notifications.ToastNotification"

    # ============================================================================
    # WinRT API Imports
    # ============================================================================

    proc RoInitialize*(initType: RO_INIT_TYPE): HRESULT
        {.stdcall, dynlib: "combase.dll", importc: "RoInitialize".}

    proc RoUninitialize*()
        {.stdcall, dynlib: "combase.dll", importc: "RoUninitialize".}

    proc RoActivateInstance*(activatableClassId: HSTRING, instance: ptr pointer): HRESULT
        {.stdcall, dynlib: "combase.dll", importc: "RoActivateInstance".}

    proc RoGetActivationFactory*(activatableClassId: HSTRING, iid: ptr GUID, factory: ptr pointer): HRESULT
        {.stdcall, dynlib: "combase.dll", importc: "RoGetActivationFactory".}

    proc WindowsCreateStringReference*(
        sourceString : LPCWSTR
        ,length       : UINT32
        ,hstringHeader: ptr HSTRING_HEADER
        ,string       : ptr HSTRING
    ): HRESULT {.stdcall, dynlib: "combase.dll", importc: "WindowsCreateStringReference".}

    proc WindowsDeleteString*(string: HSTRING): HRESULT
        {.stdcall, dynlib: "combase.dll", importc: "WindowsDeleteString".}

    # ============================================================================
    # Helper Functions
    # ============================================================================

    proc createHString*(s: string): tuple[hstring: HSTRING, header: HSTRING_HEADER] =
        ## Create an HSTRING from a Nim string
        let ws = newWideCString(s)
        var header: HSTRING_HEADER
        var hs: HSTRING

        let hr = WindowsCreateStringReference(
            cast[LPCWSTR](addr ws[0])
            ,ws.len.UINT32
            ,addr header
            ,addr hs
        )
        if FAILED(hr):
            raise newException(OSError, "Failed to create HSTRING: " & $hr)

        result = (hs, header)

    proc createHStringW*(ws: WideCString): tuple[hstring: HSTRING, header: HSTRING_HEADER] =
        ## Create an HSTRING from a wide string
        var header: HSTRING_HEADER
        var hs: HSTRING

        let hr = WindowsCreateStringReference(
            cast[LPCWSTR](addr ws[0])
            ,ws.len.UINT32
            ,addr header
            ,addr hs
        )
        if FAILED(hr):
            raise newException(OSError, "Failed to create HSTRING: " & $hr)

        result = (hs, header)

    # ============================================================================
    # Toast Public Types
    # ============================================================================

    type
        ToastScenario* = enum
            tsDefault   = "default"
            tsAlarm     = "alarm"
            tsReminder  = "reminder"
            tsIncoming  = "incomingCall"
            tsUrgent    = "urgent"

        ToastDuration* = enum
            tdShort = "short"
            tdLong  = "long"

        ToastDismissReason* = enum
            tdrUserCanceled
            tdrApplicationHidden
            tdrTimedOut

        ToastResult* = object
            kind*     : string
            arguments*: string
            userInput*: Table[string, string]
            reason*   : ToastDismissReason
            errorCode*: int32

        ToastImage* = object
            src*      : string
            alt*      : string
            placement*: string
            hintCrop* : string

        ToastProgress* = object
            title*              : string
            status*             : string
            value*              : string
            valueStringOverride*: string

        ToastAudio* = object
            src*   : string
            loop*  : bool
            silent*: bool

        ToastButton* = object
            content*       : string
            arguments*     : string
            activationType*: string

        ToastInput* = object
            id*               : string
            inputType*        : string
            placeHolderContent*: string
            title*            : string

        ToastSelection* = object
            inputId*  : string
            items*    : seq[tuple[id: string, content: string]]

        ToastNotificationHandle* = object
            notification* : pointer
            notifier*     : pointer

    # ============================================================================
    # Toast XML Builder
    # ============================================================================

    const DEFAULT_APP_ID* = "Nim"

    proc escapeXml*(s: string): string =
        ## Escape XML special characters
        result = s
        result = result.replace("&", "&amp;")
        result = result.replace("<", "&lt;")
        result = result.replace(">", "&gt;")
        result = result.replace("\"", "&quot;")
        result = result.replace("'", "&apos;")

    type
        ToastBuilder* = ref object
            title*        : string
            body*         : string
            attribution*  : string
            scenario*     : ToastScenario
            duration*     : Option[ToastDuration]
            launch*       : string
            icon*         : Option[ToastImage]
            image*        : Option[ToastImage]
            progress*     : Option[ToastProgress]
            audio*        : Option[ToastAudio]
            inputs*       : seq[ToastInput]
            selections*   : seq[ToastSelection]
            buttons*      : seq[ToastButton]
            tag*          : string
            group*        : string

    proc newToastBuilder*(): ToastBuilder =
        ## Create a new toast builder
        result = ToastBuilder(
            scenario : tsDefault
            ,duration : none(ToastDuration)
            ,icon     : none(ToastImage)
            ,image    : none(ToastImage)
            ,progress : none(ToastProgress)
            ,audio    : none(ToastAudio)
            ,inputs   : @[]
            ,selections: @[]
            ,buttons  : @[]
        )

    proc setTitle*(builder: ToastBuilder, title: string): ToastBuilder {.discardable.} =
        builder.title = title
        result = builder

    proc setBody*(builder: ToastBuilder, body: string): ToastBuilder {.discardable.} =
        builder.body = body
        result = builder

    proc setAttribution*(builder: ToastBuilder, attribution: string): ToastBuilder {.discardable.} =
        builder.attribution = attribution
        result = builder

    proc setScenario*(builder: ToastBuilder, scenario: ToastScenario): ToastBuilder {.discardable.} =
        builder.scenario = scenario
        result = builder

    proc setDuration*(builder: ToastBuilder, duration: ToastDuration): ToastBuilder {.discardable.} =
        builder.duration = some(duration)
        result = builder

    proc setLaunch*(builder: ToastBuilder, launch: string): ToastBuilder {.discardable.} =
        builder.launch = launch
        result = builder

    proc setIcon*(builder: ToastBuilder, src: string, placement = "appLogoOverride", hintCrop = "circle"): ToastBuilder {.discardable.} =
        builder.icon = some(ToastImage(src: src, placement: placement, hintCrop: hintCrop))
        result = builder

    proc setImage*(builder: ToastBuilder, src: string, placement = "", alt = ""): ToastBuilder {.discardable.} =
        builder.image = some(ToastImage(src: src, placement: placement, alt: alt))
        result = builder

    proc setProgress*(builder: ToastBuilder, title, status, value: string, valueStringOverride = ""): ToastBuilder {.discardable.} =
        builder.progress = some(ToastProgress(
            title              : title
            ,status             : status
            ,value              : value
            ,valueStringOverride: valueStringOverride
        ))
        result = builder

    proc setAudio*(builder: ToastBuilder, src: string, loop = false, silent = false): ToastBuilder {.discardable.} =
        builder.audio = some(ToastAudio(src: src, loop: loop, silent: silent))
        result = builder

    proc setSilent*(builder: ToastBuilder): ToastBuilder {.discardable.} =
        builder.audio = some(ToastAudio(silent: true))
        result = builder

    proc addInput*(builder: ToastBuilder, id: string, inputType = "text", placeHolderContent = "", title = ""): ToastBuilder {.discardable.} =
        builder.inputs.add(ToastInput(
            id                : id
            ,inputType         : inputType
            ,placeHolderContent: placeHolderContent
            ,title             : title
        ))
        result = builder

    proc addSelection*(builder: ToastBuilder, inputId: string, items: seq[tuple[id: string, content: string]]): ToastBuilder {.discardable.} =
        builder.selections.add(ToastSelection(inputId: inputId, items: items))
        result = builder

    proc addButton*(builder: ToastBuilder, content: string, arguments = "", activationType = "protocol"): ToastBuilder {.discardable.} =
        var args = arguments
        if args == "":
            args = "http:" & content
        builder.buttons.add(ToastButton(
            content        : content
            ,arguments      : args
            ,activationType : activationType
        ))
        result = builder

    proc setTag*(builder: ToastBuilder, tag: string): ToastBuilder {.discardable.} =
        builder.tag = tag
        result = builder

    proc setGroup*(builder: ToastBuilder, group: string): ToastBuilder {.discardable.} =
        builder.group = group
        result = builder

    proc buildXml*(builder: ToastBuilder): string =
        ## Build the toast XML from the builder
        var xml = ""

        # Toast root element
        xml.add("<toast ")
        xml.add(fmt"""activationType="protocol" """)

        if builder.launch.len > 0:
            xml.add(fmt"""launch="{escapeXml(builder.launch)}" """)
        else:
            xml.add("""launch="http:" """)

        xml.add(fmt"""scenario="{$builder.scenario}" """)

        if builder.duration.isSome:
            xml.add(fmt"""duration="{$builder.duration.get}" """)

        xml.add(">\n")

        # Visual section
        xml.add("  <visual>\n")
        xml.add("    <binding template=\"ToastGeneric\">\n")

        # Title
        if builder.title.len > 0:
            xml.add(fmt"""      <text><![CDATA[{builder.title}]]></text>""" & "\n")

        # Body
        if builder.body.len > 0:
            xml.add(fmt"""      <text><![CDATA[{builder.body}]]></text>""" & "\n")

        # Attribution
        if builder.attribution.len > 0:
            xml.add(fmt"""      <text placement="attribution"><![CDATA[{builder.attribution}]]></text>""" & "\n")

        # Icon (app logo override)
        if builder.icon.isSome:
            let icon = builder.icon.get
            xml.add(fmt"""      <image placement="{icon.placement}" hint-crop="{icon.hintCrop}" src="{escapeXml(icon.src)}"/>""" & "\n")

        # Image
        if builder.image.isSome:
            let img = builder.image.get
            xml.add("      <image ")
            if img.placement.len > 0:
                xml.add(fmt"""placement="{img.placement}" """)
            xml.add(fmt"""src="{escapeXml(img.src)}" """)
            if img.alt.len > 0:
                xml.add(fmt"""alt="{escapeXml(img.alt)}" """)
            xml.add("/>\n")

        # Progress bar
        if builder.progress.isSome:
            let prog = builder.progress.get
            xml.add("      <progress ")
            xml.add("""title="{title}" """)
            xml.add("""status="{status}" """)
            xml.add("""value="{value}" """)
            if prog.valueStringOverride.len > 0:
                xml.add("""valueStringOverride="{valueStringOverride}" """)
            xml.add("/>\n")

        xml.add("    </binding>\n")
        xml.add("  </visual>\n")

        # Actions section
        if builder.inputs.len > 0 or builder.selections.len > 0 or builder.buttons.len > 0:
            xml.add("  <actions>\n")

            # Inputs
            for input in builder.inputs:
                xml.add("    <input ")
                xml.add(fmt"""id="{escapeXml(input.id)}" """)
                xml.add(fmt"""type="{input.inputType}" """)
                if input.placeHolderContent.len > 0:
                    xml.add(fmt"""placeHolderContent="{escapeXml(input.placeHolderContent)}" """)
                if input.title.len > 0:
                    xml.add(fmt"""title="{escapeXml(input.title)}" """)
                xml.add("/>\n")

            # Selections
            for selection in builder.selections:
                xml.add("    <input ")
                xml.add(fmt"""id="{escapeXml(selection.inputId)}" """)
                xml.add("""type="selection" """)
                xml.add(">\n")
                for item in selection.items:
                    xml.add(fmt"""      <selection id="{escapeXml(item.id)}" content="{escapeXml(item.content)}"/>""" & "\n")
                xml.add("    </input>\n")

            # Buttons
            for btn in builder.buttons:
                xml.add("    <action ")
                xml.add(fmt"""activationType="{btn.activationType}" """)
                xml.add(fmt"""arguments="{escapeXml(btn.arguments)}" """)
                xml.add(fmt"""content="{escapeXml(btn.content)}" """)
                xml.add("/>\n")

            xml.add("  </actions>\n")

        # Audio section
        if builder.audio.isSome:
            let aud = builder.audio.get
            xml.add("  <audio ")
            if aud.silent:
                xml.add("""silent="true" """)
            else:
                xml.add(fmt"""src="{escapeXml(aud.src)}" """)
                if aud.loop:
                    xml.add("""loop="true" """)
            xml.add("/>\n")

        xml.add("</toast>")
        result = xml

    # ============================================================================
    # Core Toast Functions
    # ============================================================================

    var winrtInitialized = false

    proc initWinRT*() =
        ## Initialize the WinRT runtime
        if not winrtInitialized:
            let hr = RoInitialize(RO_INIT_MULTITHREADED)
            if FAILED(hr) and hr != RPC_E_CHANGED_MODE:
                raise newException(OSError, "Failed to initialize WinRT: " & $hr)
            winrtInitialized = true

    proc uninitWinRT*() =
        ## Uninitialize the WinRT runtime
        if winrtInitialized:
            RoUninitialize()
            winrtInitialized = false

    proc createXmlDocumentFromString(xmlString: string): pointer =
        ## Create an XmlDocument from an XML string
        initWinRT()

        # Create HSTRING for XmlDocument runtime class
        let wsClassName = newWideCString(RuntimeClass_XmlDocument)
        var headerClassName: HSTRING_HEADER
        var hsClassName: HSTRING

        var hr = WindowsCreateStringReference(
            cast[LPCWSTR](addr wsClassName[0])
            ,wsClassName.len.UINT32
            ,addr headerClassName
            ,addr hsClassName
        )
        if FAILED(hr):
            raise newException(OSError, "Failed to create XmlDocument class string: " & $hr)

        # Activate the XmlDocument instance
        var pInspectable: pointer
        hr = RoActivateInstance(hsClassName, addr pInspectable)
        if FAILED(hr):
            raise newException(OSError, "Failed to activate XmlDocument: " & $hr)

        # Get IXmlDocument interface
        var xmlDoc: ptr IXmlDocument
        var iidDoc = IID_IXmlDocument
        hr = cast[ptr IInspectable](pInspectable).lpVtbl.QueryInterface(
            pInspectable
            ,addr iidDoc
            ,cast[ptr pointer](addr xmlDoc)
        )
        discard cast[ptr IInspectable](pInspectable).lpVtbl.Release(pInspectable)

        if FAILED(hr):
            raise newException(OSError, "Failed to get IXmlDocument: " & $hr)

        # Get IXmlDocumentIO interface
        var docIO: ptr IXmlDocumentIO
        var iidDocIO = IID_IXmlDocumentIO
        hr = xmlDoc.lpVtbl.QueryInterface(
            cast[pointer](xmlDoc)
            ,addr iidDocIO
            ,cast[ptr pointer](addr docIO)
        )
        if FAILED(hr):
            discard xmlDoc.lpVtbl.Release(cast[pointer](xmlDoc))
            raise newException(OSError, "Failed to get IXmlDocumentIO: " & $hr)

        # Create HSTRING for XML content
        let wsXml = newWideCString(xmlString)
        var headerXml: HSTRING_HEADER
        var hsXml: HSTRING

        hr = WindowsCreateStringReference(
            cast[LPCWSTR](addr wsXml[0])
            ,wsXml.len.UINT32
            ,addr headerXml
            ,addr hsXml
        )
        if FAILED(hr):
            discard docIO.lpVtbl.Release(cast[pointer](docIO))
            discard xmlDoc.lpVtbl.Release(cast[pointer](xmlDoc))
            raise newException(OSError, "Failed to create XML string: " & $hr)

        # Load the XML
        hr = docIO.lpVtbl.LoadXml(cast[pointer](docIO), hsXml)
        discard docIO.lpVtbl.Release(cast[pointer](docIO))

        if FAILED(hr):
            discard xmlDoc.lpVtbl.Release(cast[pointer](xmlDoc))
            raise newException(OSError, "Failed to load XML: " & $hr)

        result = cast[pointer](xmlDoc)

    proc showToast*(xmlString: string, appId = DEFAULT_APP_ID): ToastNotificationHandle =
        ## Show a toast notification with the given XML
        initWinRT()

        # Create XML document
        var inputXml = createXmlDocumentFromString(xmlString)

        # Get ToastNotificationManager factory
        let wsToastMan = newWideCString(RuntimeClass_ToastNotificationManager)
        var headerToastMan: HSTRING_HEADER
        var hsToastMan: HSTRING

        var hr = WindowsCreateStringReference(
            cast[LPCWSTR](addr wsToastMan[0])
            ,wsToastMan.len.UINT32
            ,addr headerToastMan
            ,addr hsToastMan
        )
        if FAILED(hr):
            discard cast[ptr IXmlDocument](inputXml).lpVtbl.Release(inputXml)
            raise newException(OSError, "Failed to create ToastNotificationManager string: " & $hr)

        var toastStatics: ptr IToastNotificationManagerStatics
        var iidStatics = IID_IToastNotificationManagerStatics
        hr = RoGetActivationFactory(
            hsToastMan
            ,addr iidStatics
            ,cast[ptr pointer](addr toastStatics)
        )
        if FAILED(hr):
            discard cast[ptr IXmlDocument](inputXml).lpVtbl.Release(inputXml)
            raise newException(OSError, "Failed to get ToastNotificationManager factory: " & $hr)

        # Create toast notifier with app ID
        let wsAppId = newWideCString(appId)
        var headerAppId: HSTRING_HEADER
        var hsAppId: HSTRING

        hr = WindowsCreateStringReference(
            cast[LPCWSTR](addr wsAppId[0])
            ,wsAppId.len.UINT32
            ,addr headerAppId
            ,addr hsAppId
        )
        if FAILED(hr):
            discard toastStatics.lpVtbl.Release(cast[pointer](toastStatics))
            discard cast[ptr IXmlDocument](inputXml).lpVtbl.Release(inputXml)
            raise newException(OSError, "Failed to create app ID string: " & $hr)

        var notifier: ptr IToastNotifier
        hr = toastStatics.lpVtbl.CreateToastNotifierWithId(
            cast[pointer](toastStatics)
            ,hsAppId
            ,cast[ptr pointer](addr notifier)
        )
        if FAILED(hr):
            # Try without app ID
            hr = toastStatics.lpVtbl.CreateToastNotifier(
                cast[pointer](toastStatics)
                ,cast[ptr pointer](addr notifier)
            )
        discard toastStatics.lpVtbl.Release(cast[pointer](toastStatics))

        if FAILED(hr):
            discard cast[ptr IXmlDocument](inputXml).lpVtbl.Release(inputXml)
            raise newException(OSError, "Failed to create toast notifier: " & $hr)

        # Get ToastNotification factory
        let wsToastNotif = newWideCString(RuntimeClass_ToastNotification)
        var headerToastNotif: HSTRING_HEADER
        var hsToastNotif: HSTRING

        hr = WindowsCreateStringReference(
            cast[LPCWSTR](addr wsToastNotif[0])
            ,wsToastNotif.len.UINT32
            ,addr headerToastNotif
            ,addr hsToastNotif
        )
        if FAILED(hr):
            discard notifier.lpVtbl.Release(cast[pointer](notifier))
            discard cast[ptr IXmlDocument](inputXml).lpVtbl.Release(inputXml)
            raise newException(OSError, "Failed to create ToastNotification string: " & $hr)

        var notifFactory: ptr IToastNotificationFactory
        var iidFactory = IID_IToastNotificationFactory
        hr = RoGetActivationFactory(
            hsToastNotif
            ,addr iidFactory
            ,cast[ptr pointer](addr notifFactory)
        )
        if FAILED(hr):
            discard notifier.lpVtbl.Release(cast[pointer](notifier))
            discard cast[ptr IXmlDocument](inputXml).lpVtbl.Release(inputXml)
            raise newException(OSError, "Failed to get ToastNotification factory: " & $hr)

        # Create the toast notification
        var toast: ptr IToastNotification
        hr = notifFactory.lpVtbl.CreateToastNotification(
            cast[pointer](notifFactory)
            ,inputXml
            ,cast[ptr pointer](addr toast)
        )
        discard notifFactory.lpVtbl.Release(cast[pointer](notifFactory))
        discard cast[ptr IXmlDocument](inputXml).lpVtbl.Release(inputXml)

        if FAILED(hr):
            discard notifier.lpVtbl.Release(cast[pointer](notifier))
            raise newException(OSError, "Failed to create toast notification: " & $hr)

        # Show the toast
        hr = notifier.lpVtbl.Show(cast[pointer](notifier), cast[pointer](toast))
        if FAILED(hr):
            discard toast.lpVtbl.Release(cast[pointer](toast))
            discard notifier.lpVtbl.Release(cast[pointer](notifier))
            raise newException(OSError, "Failed to show toast: " & $hr)

        # Wait briefly for COM threads to deliver notification
        Sleep(10)

        result = ToastNotificationHandle(
            notification : cast[pointer](toast)
            ,notifier     : cast[pointer](notifier)
        )

    proc releaseToast*(handle: ToastNotificationHandle) =
        ## Release toast notification resources
        if handle.notification != nil:
            discard cast[ptr IToastNotification](handle.notification).lpVtbl.Release(handle.notification)
        if handle.notifier != nil:
            discard cast[ptr IToastNotifier](handle.notifier).lpVtbl.Release(handle.notifier)

    # ============================================================================
    # High-Level API (matches Python win11toast)
    # ============================================================================

    proc toast*(
        title      : string = ""
        ,body       : string = ""
        ,appId      : string = DEFAULT_APP_ID
        ,icon       : string = ""
        ,image      : string = ""
        ,duration   : Option[ToastDuration] = none(ToastDuration)
        ,scenario   : ToastScenario = tsDefault
        ,launch     : string = ""
        ,audio      : string = ""
        ,silent     : bool = false
        ,inputs     : seq[string] = @[]
        ,buttons    : seq[string] = @[]
        ,tag        : string = ""
        ,group      : string = ""
    ): ToastNotificationHandle =
        ## Show a toast notification (simple API matching Python win11toast)
        ## 
        ## Example:
        ##   discard toast("Hello", "World!")
        ##   discard toast("Hello", "Click me", launch="https://www.example.com")

        var builder = newToastBuilder()
            .setTitle(title)
            .setBody(body)
            .setScenario(scenario)
            .setLaunch(launch)
            .setTag(tag)
            .setGroup(group)

        if duration.isSome:
            builder.setDuration(duration.get)

        if icon.len > 0:
            builder.setIcon(icon)

        if image.len > 0:
            builder.setImage(image)

        if silent:
            builder.setSilent()
        elif audio.len > 0:
            builder.setAudio(audio)

        for input in inputs:
            builder.addInput(input, placeHolderContent = input)

        for button in buttons:
            builder.addButton(button)

        let xml = builder.buildXml()
        result = showToast(xml, appId)

    proc notify*(
        title      : string = ""
        ,body       : string = ""
        ,appId      : string = DEFAULT_APP_ID
        ,icon       : string = ""
        ,image      : string = ""
        ,duration   : Option[ToastDuration] = none(ToastDuration)
        ,scenario   : ToastScenario = tsDefault
        ,launch     : string = ""
        ,audio      : string = ""
        ,silent     : bool = false
        ,inputs     : seq[string] = @[]
        ,buttons    : seq[string] = @[]
        ,tag        : string = ""
        ,group      : string = ""
    ) =
        ## Show a toast notification (fire and forget)
        let handle = toast(
            title    = title
            ,body     = body
            ,appId    = appId
            ,icon     = icon
            ,image    = image
            ,duration = duration
            ,scenario = scenario
            ,launch   = launch
            ,audio    = audio
            ,silent   = silent
            ,inputs   = inputs
            ,buttons  = buttons
            ,tag      = tag
            ,group    = group
        )
        releaseToast(handle)

else:
    # Stub for non-Windows platforms
    proc initWinRT*()   = discard
    proc uninitWinRT*() = discard

    proc toast*(
        title      : string = ""
        ,body       : string = ""
        ,appId      : string = ""
        ,icon       : string = ""
        ,image      : string = ""
        ,duration   : Option[ToastDuration] = none(ToastDuration)
        ,scenario   : ToastScenario = tsDefault
        ,launch     : string = ""
        ,audio      : string = ""
        ,silent     : bool = false
        ,inputs     : seq[string] = @[]
        ,buttons    : seq[string] = @[]
        ,tag        : string = ""
        ,group      : string = ""
    ): ToastNotificationHandle =
        echo "Toast notifications are only available on Windows"

    proc notify*(
        title      : string = ""
        ,body       : string = ""
        ,appId      : string = ""
        ,icon       : string = ""
        ,image      : string = ""
        ,duration   : Option[ToastDuration] = none(ToastDuration)
        ,scenario   : ToastScenario = tsDefault
        ,launch     : string = ""
        ,audio      : string = ""
        ,silent     : bool = false
        ,inputs     : seq[string] = @[]
        ,buttons    : seq[string] = @[]
        ,tag        : string = ""
        ,group      : string = ""
    ) =
        echo "Toast notifications are only available on Windows"

# ============================================================================
# Module initialization/cleanup
# ============================================================================

when isMainModule:
    # Simple test
    echo "Win11Toast - Windows Toast Notifications for Nim"
    when defined(windows):
        proc main() =
            initWinRT()
            defer: uninitWinRT()

            # Test basic toast
            notify(
                title  = "Hello from Nim!"
                ,body   = "This is a test notification."
                ,silent = true
            )
            echo "Toast sent!"

        main()
    else:
        echo "This module only works on Windows."