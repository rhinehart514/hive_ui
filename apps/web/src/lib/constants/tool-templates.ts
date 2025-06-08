// HIVE vBETA - 5 Core Tool Templates
// These are the foundational templates builders can customize

import { ToolTemplate, ToolElement } from '../types/spaces';

// Helper function to create element configs
const createElement = (
  type: string,
  config: Record<string, any>,
  position: number,
  isRequired: boolean = false
): ToolElement => ({
  id: `${type}_${position}`,
  type,
  config,
  position,
  isRequired
});

export const CORE_TOOL_TEMPLATES: ToolTemplate[] = [
  // 1. 1-Question Poll - Quick feedback and decisions
  {
    id: 'quick_poll',
    name: '1-Question Poll',
    description: 'Get quick feedback from your space with a simple poll question',
    category: 'feedback',
    isCustomizable: true,
    defaultElements: [
      createElement('poll_question', {
        placeholder: 'What should we do for our next event?',
        allowMultipleChoice: false,
        maxOptions: 4
      }, 1, true),
      createElement('poll_options', {
        options: ['Option 1', 'Option 2', 'Option 3'],
        allowOther: true
      }, 2, true),
      createElement('poll_settings', {
        anonymous: false,
        showResults: 'after_vote',
        closeAfter: '7_days'
      }, 3, false)
    ]
  },

  // 2. Anonymous Suggest Box - Safe feedback collection
  {
    id: 'suggest_box',
    name: 'Anonymous Suggest Box',
    description: 'Collect anonymous suggestions and feedback from space members',
    category: 'feedback',
    isCustomizable: true,
    defaultElements: [
      createElement('text_prompt', {
        title: 'Suggestion Box',
        placeholder: 'Share your ideas or feedback anonymously...',
        maxLength: 500
      }, 1, true),
      createElement('category_selector', {
        categories: ['Event Ideas', 'Space Improvements', 'General Feedback', 'Other'],
        required: false
      }, 2, false),
      createElement('submission_settings', {
        anonymous: true,
        requireModeration: true,
        notifyBuilders: true
      }, 3, false)
    ]
  },

  // 3. Resource Board - Link sharing and organization
  {
    id: 'resource_board',
    name: 'Resource Board',
    description: 'Share and organize useful links, documents, and resources',
    category: 'productivity',
    isCustomizable: true,
    defaultElements: [
      createElement('resource_input', {
        fields: ['title', 'url', 'description'],
        requireTitle: true,
        requireUrl: true,
        allowFiles: true
      }, 1, true),
      createElement('category_tags', {
        predefinedTags: ['Study Materials', 'Career Resources', 'Social Events', 'Academic'],
        allowCustomTags: true,
        maxTags: 3
      }, 2, false),
      createElement('display_settings', {
        sortBy: 'newest',
        showCategories: true,
        allowVoting: true,
        gridLayout: true
      }, 3, false)
    ]
  },

  // 4. Study Tracker - Academic coordination
  {
    id: 'study_tracker',
    name: 'Study Tracker',
    description: 'Coordinate study sessions and track academic activities',
    category: 'coordination',
    isCustomizable: true,
    defaultElements: [
      createElement('study_session', {
        fields: ['subject', 'location', 'time', 'duration'],
        allowRecurring: true,
        maxParticipants: 10
      }, 1, true),
      createElement('subject_selector', {
        commonSubjects: ['Computer Science', 'Mathematics', 'Business', 'Engineering'],
        allowCustom: true
      }, 2, false),
      createElement('coordination_tools', {
        showAttendees: true,
        allowChat: true,
        sendReminders: true,
        exportCalendar: true
      }, 3, false)
    ]
  },

  // 5. Attendance Log - Event and meeting tracking
  {
    id: 'attendance_log',
    name: 'Attendance Log',
    description: 'Track attendance for meetings, events, and activities',
    category: 'coordination',
    isCustomizable: true,
    defaultElements: [
      createElement('event_details', {
        fields: ['event_name', 'date', 'time', 'location'],
        allowDescription: true,
        requireAll: true
      }, 1, true),
      createElement('attendance_tracking', {
        methods: ['qr_code', 'manual_checkin', 'location_based'],
        defaultMethod: 'manual_checkin',
        allowLateCheckin: true
      }, 2, true),
      createElement('attendance_display', {
        showNames: true,
        exportOptions: ['csv', 'pdf'],
        sendSummary: true,
        trackStats: true
      }, 3, false)
    ]
  }
];

// Template categories for filtering and organization
export const TEMPLATE_CATEGORIES = {
  social: {
    name: 'Social',
    description: 'Tools for community building and engagement',
    color: '#FFD700'
  },
  productivity: {
    name: 'Productivity', 
    description: 'Tools for organization and resource management',
    color: '#8CE563'
  },
  coordination: {
    name: 'Coordination',
    description: 'Tools for planning and activity management',
    color: '#56CCF2'
  },
  feedback: {
    name: 'Feedback',
    description: 'Tools for collecting input and opinions',
    color: '#FF9500'
  }
} as const;

// Element types available for customization
export const AVAILABLE_ELEMENT_TYPES = {
  // Input Elements
  'text_input': 'Text Input Field',
  'text_area': 'Large Text Area',
  'number_input': 'Number Input',
  'date_input': 'Date Picker',
  'time_input': 'Time Picker',
  'file_upload': 'File Upload',
  'image_upload': 'Image Upload',
  
  // Selection Elements
  'dropdown': 'Dropdown Menu',
  'radio_buttons': 'Radio Button Group',
  'checkboxes': 'Checkbox Group',
  'category_selector': 'Category Tags',
  'rating_scale': 'Rating Scale',
  
  // Poll Elements
  'poll_question': 'Poll Question',
  'poll_options': 'Poll Options',
  'poll_settings': 'Poll Configuration',
  
  // Display Elements
  'rich_text': 'Rich Text Display',
  'image_display': 'Image Display',
  'link_preview': 'Link Preview Card',
  'progress_bar': 'Progress Indicator',
  
  // Coordination Elements
  'event_details': 'Event Information',
  'attendance_tracking': 'Attendance Tracker',
  'study_session': 'Study Session Planner',
  'resource_input': 'Resource Submission',
  
  // Settings Elements
  'submission_settings': 'Submission Rules',
  'display_settings': 'Display Options',
  'notification_settings': 'Notification Rules',
  'privacy_settings': 'Privacy Controls'
} as const;

// Default configurations for new elements
export const ELEMENT_DEFAULTS = {
  text_input: {
    placeholder: 'Enter text...',
    maxLength: 200,
    required: false
  },
  poll_question: {
    placeholder: 'Ask your question...',
    allowMultipleChoice: false,
    maxOptions: 5
  },
  file_upload: {
    allowedTypes: ['pdf', 'doc', 'docx', 'txt'],
    maxSize: '10MB',
    multiple: false
  },
  attendance_tracking: {
    methods: ['manual_checkin'],
    allowLateCheckin: true,
    requireLocation: false
  }
} as const;

// Export template lookup functions
export const getTemplateById = (id: string): ToolTemplate | undefined => {
  return CORE_TOOL_TEMPLATES.find(template => template.id === id);
};

export const getTemplatesByCategory = (category: string): ToolTemplate[] => {
  return CORE_TOOL_TEMPLATES.filter(template => template.category === category);
};

export default CORE_TOOL_TEMPLATES; 