// ── Mock Users ──
export const mockUsers = [
  { id: 1, name: 'Ayesha Khan',    email: 'ayesha@email.com', phone: '0300-1234567', status: 'active',   joined: '2024-01-15', bookings: 12, role: 'Customer', lastActive: '2 hours ago', avatar: 'AK' },
  { id: 2, name: 'Bilal Ahmed',    email: 'bilal@email.com',  phone: '0311-9876543', status: 'active',   joined: '2024-02-20', bookings: 7,  role: 'Customer', lastActive: '1 day ago', avatar: 'BA' },
  { id: 3, name: 'Sara Malik',     email: 'sara@email.com',   phone: '0321-5555555', status: 'inactive', joined: '2024-03-05', bookings: 3,  role: 'Customer', lastActive: '5 days ago', avatar: 'SM' },
  { id: 4, name: 'Usman Tariq',    email: 'usman@email.com',  phone: '0333-1111222', status: 'active',   joined: '2024-04-10', bookings: 19, role: 'Customer', lastActive: '15 mins ago', avatar: 'UT' },
  { id: 5, name: 'Fatima Zahra',   email: 'fatima@email.com', phone: '0345-9999000', status: 'blocked',  joined: '2024-05-01', bookings: 1,  role: 'Customer', lastActive: '1 week ago', avatar: 'FZ' },
  { id: 6, name: 'Ali Raza',       email: 'ali.raza@email.com', phone: '0300-2222333', status: 'active',   joined: '2024-01-18', bookings: 34, role: 'Electrician', lastActive: '10 mins ago', avatar: 'AR' },
  { id: 7, name: 'Kamran Iqbal',   email: 'kamran.iqbal@email.com', phone: '0300-3333444', status: 'active',   joined: '2024-02-10', bookings: 58, role: 'Plumber', lastActive: '45 mins ago', avatar: 'KI' },
  { id: 8, name: 'Imran Butt',     email: 'imran.butt@email.com', phone: '0321-6666777', status: 'active',   joined: '2024-03-12', bookings: 21, role: 'Electrician', lastActive: '3 hours ago', avatar: 'IB' },
  { id: 9, name: 'Nadeem Shah',    email: 'nadeem.shah@email.com', phone: '0333-8888999', status: 'blocked',  joined: '2024-04-05', bookings: 5,  role: 'Plumber', lastActive: '2 days ago', avatar: 'NS' },
];

// ── Mock Providers ──
export const mockProviders = [
  { id: 1, name: 'Ali Raza',       type: 'Electrician', phone: '0300-2222333', city: 'Rawalpindi', status: 'approved', quizScore: 87, attempts: 1, rating: 4.8, completedJobs: 34 },
  { id: 2, name: 'Hassan Qureshi', type: 'Plumber',     phone: '0311-4444555', city: 'Islamabad',  status: 'pending',  quizScore: null, attempts: 0, rating: null, completedJobs: 0 },
  { id: 3, name: 'Imran Butt',     type: 'Electrician', phone: '0321-6666777', city: 'Lahore',     status: 'approved', quizScore: 72, attempts: 2, rating: 4.2, completedJobs: 21 },
  { id: 4, name: 'Nadeem Shah',    type: 'Plumber',     phone: '0333-8888999', city: 'Rawalpindi', status: 'blocked',  quizScore: 41, attempts: 3, rating: 2.1, completedJobs: 5  },
  { id: 5, name: 'Tariq Mehmood',  type: 'Electrician', phone: '0345-0000111', city: 'Islamabad',  status: 'pending',  quizScore: 65, attempts: 1, rating: null, completedJobs: 0 },
  { id: 6, name: 'Kamran Iqbal',   type: 'Plumber',     phone: '0300-3333444', city: 'Karachi',    status: 'approved', quizScore: 91, attempts: 1, rating: 4.9, completedJobs: 58 },
];

// ── Mock Bookings ──
export const mockBookings = [
  {  customer: 'Ayesha Khan',  provider: 'Ali Raza',       service: 'Electrical Wiring',  date: '2024-06-01', time: '10:00 AM', status: 'completed', amount: 2500 },
  {  customer: 'Usman Tariq',  provider: 'Kamran Iqbal',   service: 'Pipe Repair',        date: '2024-06-02', time: '02:00 PM', status: 'active',    amount: 1800 },
  {  customer: 'Bilal Ahmed',  provider: 'Imran Butt',     service: 'Fan Installation',   date: '2024-06-03', time: '11:00 AM', status: 'pending',   amount: 1200 },
  {  customer: 'Sara Malik',   provider: 'Ali Raza',       service: 'Switchboard Repair', date: '2024-06-04', time: '03:00 PM', status: 'completed', amount: 800  },
  {  customer: 'Fatima Zahra', provider: 'Kamran Iqbal',   service: 'Bathroom Fitting',   date: '2024-06-05', time: '09:00 AM', status: 'cancelled', amount: 3200 },
];

// ── Mock Complaints ──
export const mockComplaints = [
  { customer: 'Ayesha Khan',  provider: 'Nadeem Shah',  type: 'Poor workmanship', date: '2024-06-01', status: 'pending',  severity: 'high',   description: 'Work done was not up to standard. Pipe started leaking again next day.' },
  { customer: 'Bilal Ahmed',  provider: 'Imran Butt',   type: 'Late arrival',     date: '2024-06-02', status: 'resolved', severity: 'low',    description: 'Provider arrived 2 hours late without notification.' },
  { customer: 'Usman Tariq',  provider: 'Ali Raza',     type: 'Overcharging',     date: '2024-06-03', status: 'pending',  severity: 'medium', description: 'Charged more than the agreed amount after job completion.' },
  { customer: 'Sara Malik',   provider: 'Nadeem Shah',  type: 'Rude behavior',    date: '2024-06-04', status: 'pending',  severity: 'high',   description: 'Provider was disrespectful and used inappropriate language.' },
];

// ── Mock Blocked Accounts ──
export const mockBlocked = [
  { name: 'Nadeem Shah',  type: 'provider', reason: 'Failed quiz 3 times + multiple complaints', date: '2024-05-30', autoBlocked: true },
  { name: 'Fatima Zahra', type: 'customer', reason: 'Repeated fraudulent booking cancellations',   date: '2024-06-01', autoBlocked: false },
];

// ── Chart Data ──
export const weeklyBookings = [
  { day: 'Mon', bookings: 12, completed: 10, cancelled: 2 },
  { day: 'Tue', bookings: 19, completed: 16, cancelled: 3 },
  { day: 'Wed', bookings: 14, completed: 12, cancelled: 2 },
  { day: 'Thu', bookings: 22, completed: 18, cancelled: 4 },
  { day: 'Fri', bookings: 31, completed: 27, cancelled: 4 },
  { day: 'Sat', bookings: 28, completed: 24, cancelled: 4 },
  { day: 'Sun', bookings: 16, completed: 14, cancelled: 2 },
];

export const providerGrowth = [
  { month: 'Jan', electricians: 12, plumbers: 8  },
  { month: 'Feb', electricians: 18, plumbers: 11 },
  { month: 'Mar', electricians: 25, plumbers: 16 },
  { month: 'Apr', electricians: 31, plumbers: 22 },
  { month: 'May', electricians: 38, plumbers: 28 },
  { month: 'Jun', electricians: 44, plumbers: 33 },
];

export const serviceCategories = [
  { name: 'Electrical', value: 45 },
  { name: 'Plumbing',   value: 55 },
];

export const complaintTrend = [
  { month: 'Jan', complaints: 4, resolved: 3 },
  { month: 'Feb', complaints: 7, resolved: 6 },
  { month: 'Mar', complaints: 5, resolved: 5 },
  { month: 'Apr', complaints: 9, resolved: 7 },
  { month: 'May', complaints: 6, resolved: 5 },
  { month: 'Jun', complaints: 4, resolved: 4 },
];

// ── Mock Quiz Questions ──
export const mockQuizQuestions = [
  {
    id: 1,
    title: 'What is the standard nominal voltage of residential AC single-phase supply in Pakistan?',
    options: ['110V', '220V', '440V', '12V'],
    correctAnswer: '220V',
    difficulty: 'Easy',
    category: 'Electrician',
    status: 'active',
    created: '2024-05-10'
  },
  {
    id: 2,
    title: 'Which color code is standard for protective grounding/earth wire in electrical systems?',
    options: ['Red', 'Black', 'Green or Green-Yellow', 'Blue'],
    correctAnswer: 'Green or Green-Yellow',
    difficulty: 'Easy',
    category: 'Electrician',
    status: 'active',
    created: '2024-05-11'
  },
  {
    id: 3,
    title: 'What rating of Miniature Circuit Breaker (MCB) is typically selected for a standard 1.5-ton AC?',
    options: ['6A', '10A', '20A', '63A'],
    correctAnswer: '20A',
    difficulty: 'Medium',
    category: 'Electrician',
    status: 'active',
    created: '2024-05-12'
  },
  {
    id: 4,
    title: 'Which law relates electric current, voltage, and electrical resistance in a closed loop?',
    options: ["Faraday's Law", "Ohm's Law", "Kirchhoff's Law", "Coulomb's Law"],
    correctAnswer: "Ohm's Law",
    difficulty: 'Easy',
    category: 'Electrician',
    status: 'active',
    created: '2024-05-13'
  },
  {
    id: 5,
    title: 'What device is used to measure electrical insulation resistance of high voltage cables?',
    options: ['Multimeter', 'Wattmeter', 'Megger', 'Oscilloscope'],
    correctAnswer: 'Megger',
    difficulty: 'Hard',
    category: 'Electrician',
    status: 'active',
    created: '2024-05-14'
  },
  {
    id: 6,
    title: 'What does an RCD (Residual Current Device) protect users against?',
    options: ['Voltage surges', 'Electric shocks & leakage', 'Short circuit heating', 'Overloading'],
    correctAnswer: 'Electric shocks & leakage',
    difficulty: 'Medium',
    category: 'Electrician',
    status: 'active',
    created: '2024-05-14'
  },
  {
    id: 7,
    title: 'What is the standard pipe diameter used for main water supply inlets in residential homes?',
    options: ['1/2 inch', '3/4 inch', '1 inch', '2 inches'],
    correctAnswer: '3/4 inch',
    difficulty: 'Easy',
    category: 'Plumber',
    status: 'active',
    created: '2024-05-09'
  },
  {
    id: 8,
    title: 'Which material is highly recommended for hot water distribution lines due to high heat tolerance?',
    options: ['PVC', 'CPVC', 'Lead', 'Galvanized Iron'],
    correctAnswer: 'CPVC',
    difficulty: 'Medium',
    category: 'Plumber',
    status: 'active',
    created: '2024-05-10'
  },
  {
    id: 9,
    title: 'What tool is used to clear blockages in standard sewer and main drainage pipes?',
    options: ['Pipe Wrench', 'Plunger', 'Drain Auger (Snake)', 'Teasing Needle'],
    correctAnswer: 'Drain Auger (Snake)',
    difficulty: 'Easy',
    category: 'Plumber',
    status: 'active',
    created: '2024-05-11'
  },
  {
    id: 10,
    title: 'What is the primary cause of water hammering in domestic water piping?',
    options: ['High water pressure', 'Sudden closing of valves', 'Air trapped in pipes', 'Corroded joints'],
    correctAnswer: 'Sudden closing of valves',
    difficulty: 'Hard',
    category: 'Plumber',
    status: 'active',
    created: '2024-05-12'
  },
  {
    id: 11,
    title: 'Which valve type provides the least resistance to flow when fully open?',
    options: ['Globe Valve', 'Gate Valve', 'Needle Valve', 'Check Valve'],
    correctAnswer: 'Gate Valve',
    difficulty: 'Medium',
    category: 'Plumber',
    status: 'inactive',
    created: '2024-05-13'
  }
];

// ── Mock Worker Verifications ──
export const mockWorkerVerifications = [
  {
    id: 101,
    name: 'Waseem Akram',
    profession: 'Electrician',
    cnicStatus: 'Pending',
    cnicNumber: '37405-1234567-3',
    quizScore: 90,
    attempts: 1,
    status: 'Pending',
    registrationDate: '2026-05-15',
    avatar: 'WA',
    documents: {
      cnicFront: 'https://images.unsplash.com/photo-1554774853-aae0a22c8aa4?w=500&auto=format&fit=crop&q=60',
      cnicBack: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=500&auto=format&fit=crop&q=60',
      license: 'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?w=500&auto=format&fit=crop&q=60'
    },
    quizDetails: [
      { question: 'What is the standard nominal voltage in Pakistan?', chosen: '220V', correct: '220V', status: 'correct' },
      { question: 'Which color code is standard for grounding wire?', chosen: 'Green or Green-Yellow', correct: 'Green or Green-Yellow', status: 'correct' },
      { question: 'What does RCD protect users against?', chosen: 'Electric shocks & leakage', correct: 'Electric shocks & leakage', status: 'correct' }
    ]
  },
  {
    id: 102,
    name: 'Tariq Mehmood',
    profession: 'Electrician',
    cnicStatus: 'Verified',
    cnicNumber: '37405-7654321-1',
    quizScore: 65,
    attempts: 1,
    status: 'Pending',
    registrationDate: '2026-05-14',
    avatar: 'TM',
    documents: {
      cnicFront: 'https://images.unsplash.com/photo-1554774853-aae0a22c8aa4?w=500&auto=format&fit=crop&q=60',
      cnicBack: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=500&auto=format&fit=crop&q=60',
      license: 'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?w=500&auto=format&fit=crop&q=60'
    },
    quizDetails: [
      { question: 'What rating of MCB is typically selected for 1.5-ton AC?', chosen: '10A', correct: '20A', status: 'incorrect' },
      { question: 'What does RCD protect users against?', chosen: 'Electric shocks & leakage', correct: 'Electric shocks & leakage', status: 'correct' },
      { question: 'What is the standard nominal voltage in Pakistan?', chosen: '220V', correct: '220V', status: 'correct' }
    ]
  },
  {
    id: 103,
    name: 'Sajid Mahmood',
    profession: 'Plumber',
    cnicStatus: 'Verified',
    cnicNumber: '34603-9876543-5',
    quizScore: 80,
    attempts: 1,
    status: 'Verified',
    registrationDate: '2026-05-10',
    avatar: 'SM',
    documents: {
      cnicFront: 'https://images.unsplash.com/photo-1554774853-aae0a22c8aa4?w=500&auto=format&fit=crop&q=60',
      cnicBack: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=500&auto=format&fit=crop&q=60',
      license: 'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?w=500&auto=format&fit=crop&q=60'
    },
    quizDetails: [
      { question: 'What is the standard pipe diameter for water inlets?', chosen: '3/4 inch', correct: '3/4 inch', status: 'correct' },
      { question: 'Which material is recommended for hot water?', chosen: 'CPVC', correct: 'CPVC', status: 'correct' },
      { question: 'What is the primary cause of water hammering?', chosen: 'Air trapped in pipes', correct: 'Sudden closing of valves', status: 'incorrect' }
    ]
  },
  {
    id: 104,
    name: 'Hassan Qureshi',
    profession: 'Plumber',
    cnicStatus: 'Under Review',
    cnicNumber: '37405-4444555-9',
    quizScore: null,
    attempts: 0,
    status: 'Under Review',
    registrationDate: '2026-05-16',
    avatar: 'HQ',
    documents: {
      cnicFront: 'https://images.unsplash.com/photo-1554774853-aae0a22c8aa4?w=500&auto=format&fit=crop&q=60',
      cnicBack: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=500&auto=format&fit=crop&q=60',
      license: 'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?w=500&auto=format&fit=crop&q=60'
    },
    quizDetails: []
  },
  {
    id: 105,
    name: 'Nadeem Shah',
    profession: 'Plumber',
    cnicStatus: 'Rejected',
    cnicNumber: '37405-8888999-7',
    quizScore: 41,
    attempts: 3,
    status: 'Rejected',
    registrationDate: '2026-05-02',
    avatar: 'NS',
    documents: {
      cnicFront: 'https://images.unsplash.com/photo-1554774853-aae0a22c8aa4?w=500&auto=format&fit=crop&q=60',
      cnicBack: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=500&auto=format&fit=crop&q=60',
      license: 'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?w=500&auto=format&fit=crop&q=60'
    },
    quizDetails: [
      { question: 'What is the primary cause of water hammering?', chosen: 'Corroded joints', correct: 'Sudden closing of valves', status: 'incorrect' },
      { question: 'Which valve type provides the least resistance?', chosen: 'Globe Valve', correct: 'Gate Valve', status: 'incorrect' },
      { question: 'What is the standard pipe diameter for water inlets?', chosen: '1/2 inch', correct: '3/4 inch', status: 'incorrect' }
    ]
  },
  {
    id: 106,
    name: 'Asif Mehmood',
    profession: 'Electrician',
    cnicStatus: 'Pending',
    cnicNumber: '35201-9988112-5',
    quizScore: 78,
    attempts: 1,
    status: 'Pending',
    registrationDate: '2026-05-17',
    avatar: 'AM',
    documents: {
      cnicFront: 'https://images.unsplash.com/photo-1554774853-aae0a22c8aa4?w=500&auto=format&fit=crop&q=60',
      cnicBack: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=500&auto=format&fit=crop&q=60',
      license: 'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?w=500&auto=format&fit=crop&q=60'
    },
    quizDetails: [
      { question: 'What is the standard nominal voltage in Pakistan?', chosen: '220V', correct: '220V', status: 'correct' },
      { question: 'Which color code is standard for grounding wire?', chosen: 'Green or Green-Yellow', correct: 'Green or Green-Yellow', status: 'correct' },
      { question: 'What does RCD protect users against?', chosen: 'Voltage surges', correct: 'Electric shocks & leakage', status: 'incorrect' }
    ]
  }
];