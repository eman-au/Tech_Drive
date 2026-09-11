import React, { useState, useMemo } from 'react';
import {
  Plus,
  Edit2,
  Trash2,
  HelpCircle,
  BookOpen,
  Zap,
  Wrench,
  Check,
  X
} from 'lucide-react';

import { useSearch } from '../../context/SearchContext';
import PageHeader from '../../components/common/PageHeader';
import StatCard from '../../components/common/StatCard';
import Badge from '../../components/common/Badge';
import { mockQuizQuestions as initialQuestions } from '../../data/mockData';

import './QuizQuestions.css';

export default function QuizQuestions() {
  const [questions, setQuestions] = useState(initialQuestions);
  const { search } = useSearch();

  const [filterProfession, setFilterProfession] = useState('All');
  const [filterDifficulty, setFilterDifficulty] = useState('All');

  const [modalOpen, setModalOpen] = useState(false);
  const [editingQuestion, setEditingQuestion] = useState(null);

  const [formTitle, setFormTitle] = useState('');
  const [formOptions, setFormOptions] = useState(['', '', '', '']);
  const [formCorrectAnswer, setFormCorrectAnswer] = useState('');
  const [formDifficulty, setFormDifficulty] = useState('Easy');
  const [formCategory, setFormCategory] = useState('Electrician');

  const stats = useMemo(() => {
    const total = questions.length;
    const electrician = questions.filter(q => q.category === 'Electrician').length;
    const plumber = questions.filter(q => q.category === 'Plumber').length;
    return { total, electrician, plumber };
  }, [questions]);

  const filteredQuestions = useMemo(() => {
    return questions.filter(q => {
      const matchesSearch =
        q.title.toLowerCase().includes(search.toLowerCase()) ||
        q.options.some(opt => opt.toLowerCase().includes(search.toLowerCase()));
      const matchesProfession = filterProfession === 'All' || q.category === filterProfession;
      const matchesDifficulty = filterDifficulty === 'All' || q.difficulty === filterDifficulty;
      return matchesSearch && matchesProfession && matchesDifficulty;
    });
  }, [questions, search, filterProfession, filterDifficulty]);

  const handleOpenAddModal = () => {
    setEditingQuestion(null);
    setFormTitle('');
    setFormOptions(['', '', '', '']);
    setFormCorrectAnswer('');
    setFormDifficulty('Easy');
    setFormCategory('Electrician');
    setModalOpen(true);
  };

  const handleOpenEditModal = q => {
    setEditingQuestion(q);
    setFormTitle(q.title);
    setFormOptions([...q.options]);
    setFormCorrectAnswer(q.correctAnswer);
    setFormDifficulty(q.difficulty);
    setFormCategory(q.category);
    setModalOpen(true);
  };

  const handleSubmit = e => {
    e.preventDefault();

    if (!formTitle.trim() || formOptions.some(opt => !opt.trim()) || !formCorrectAnswer) {
      alert('Please fill all fields and select the correct answer.');
      return;
    }

    if (!formOptions.includes(formCorrectAnswer)) {
      alert('Correct answer must match one of the options.');
      return;
    }

    if (editingQuestion) {
      setQuestions(prev =>
        prev.map(q =>
          q.id === editingQuestion.id
            ? {
                ...q,
                title: formTitle,
                options: [...formOptions],
                correctAnswer: formCorrectAnswer,
                difficulty: formDifficulty,
                category: formCategory,
              }
            : q
        )
      );
    } else {
      const newQuestion = {
        id: Date.now(),
        title: formTitle,
        options: [...formOptions],
        correctAnswer: formCorrectAnswer,
        difficulty: formDifficulty,
        category: formCategory,
        status: 'active',
        created: new Date().toISOString().split('T')[0],
      };
      setQuestions(prev => [newQuestion, ...prev]);
    }

    setModalOpen(false);
  };

  const handleDeleteQuestion = id => {
    if (window.confirm('Are you sure you want to delete this question?')) {
      setQuestions(prev => prev.filter(q => q.id !== id));
    }
  };

  return (
    <div className="quiz-questions animate-fade">
      <PageHeader
        title="Quiz Questions"
        subtitle="Manage, structure, and categorize competency questions for plumbing and electrical service providers."
      />

      {/* Stat Cards */}
      <div className="quiz-stats-grid">
        <div
          className={`quiz-stat-card-clickable ${filterProfession === 'All' ? 'quiz-stat-card--active' : ''}`}
          onClick={() => setFilterProfession('All')}
        >
          <StatCard title="Total Questions" value={stats.total} icon={BookOpen} color="green" />
        </div>

        <div
          className={`quiz-stat-card-clickable ${filterProfession === 'Electrician' ? 'quiz-stat-card--active' : ''}`}
          onClick={() => setFilterProfession('Electrician')}
        >
          <StatCard title="Electrician Questions" value={stats.electrician} icon={Zap} color="yellow" />
        </div>

        <div
          className={`quiz-stat-card-clickable ${filterProfession === 'Plumber' ? 'quiz-stat-card--active' : ''}`}
          onClick={() => setFilterProfession('Plumber')}
        >
          <StatCard title="Plumber Questions" value={stats.plumber} icon={Wrench} color="cyan" />
        </div>
      </div>

      {/* Toolbar */}
      <div className="quiz-toolbar">
        <div className="quiz-toolbar__filters">

          {/* Profession filter */}
          <div className="quiz-btn-group">
            {['All', 'Electrician', 'Plumber'].map(p => (
              <button
                key={p}
                className={`quiz-btn-filter ${filterProfession === p ? 'quiz-btn-filter--active' : ''}`}
                onClick={() => setFilterProfession(p)}
              >
                {p === 'All' ? 'All Professions' : p}
              </button>
            ))}
          </div>

          {/* Difficulty filter */}
          <div className="quiz-btn-group">
            {['All', 'Easy', 'Medium', 'Hard'].map(d => (
              <button
                key={d}
                className={`quiz-btn-filter ${filterDifficulty === d ? 'quiz-btn-filter--active' : ''}`}
                onClick={() => setFilterDifficulty(d)}
              >
                {d === 'All' ? 'All Levels' : d}
              </button>
            ))}
          </div>

        </div>

        <button className="btn btn--primary" onClick={handleOpenAddModal}>
          <Plus size={16} />
          Create Question
        </button>
      </div>

      {/* Table */}
      <div className="table-card">
        {filteredQuestions.length === 0 ? (
          <div className="quiz-empty-state">
            <HelpCircle size={48} className="empty-icon" />
            <h3>No Questions Found</h3>
            <p>Try adjusting your filters or create a new question.</p>
          </div>
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th style={{ width: '55%' }}>Question Title</th>
                <th style={{ width: '15%' }}>Profession</th>
                <th style={{ width: '12%' }}>Difficulty</th>
                <th style={{ width: '18%', textAlign: 'right' }}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredQuestions.map(q => (
                <tr key={q.id}>
                  <td>
                    <div className="quiz-table-question">
                      <span className="quiz-question-text">{q.title}</span>
                      <div className="quiz-options-tags">
                        {q.options.map((opt, i) => (
                          <span
                            key={i}
                            className={`quiz-opt-tag ${opt === q.correctAnswer ? 'quiz-opt-tag--correct' : ''}`}
                          >
                            {String.fromCharCode(65 + i)}: {opt}
                          </span>
                        ))}
                      </div>
                    </div>
                  </td>
                  <td>
                    <Badge
                      label={q.category}
                      type={q.category === 'Electrician' ? 'info' : 'primary'}
                    />
                  </td>
                  <td>
                    <Badge
                      label={q.difficulty}
                      type={
                        q.difficulty === 'Easy' ? 'success'
                        : q.difficulty === 'Medium' ? 'warning'
                        : 'danger'
                      }
                    />
                  </td>
                  <td>
                    <div className="table-actions" style={{ justifyContent: 'flex-end' }}>
                      <button className="icon-btn icon-btn--info" onClick={() => handleOpenEditModal(q)}>
                        <Edit2 size={13} /> Edit
                      </button>
                      <button className="icon-btn icon-btn--danger" onClick={() => handleDeleteQuestion(q.id)}>
                        <Trash2 size={13} /> Delete
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {/* Modal */}
      {modalOpen && (
        <div className="quiz-modal-overlay">
          <div className="quiz-modal">
            <div className="quiz-modal__header">
              <h3>{editingQuestion ? 'Edit Quiz Question' : 'Create Quiz Question'}</h3>
              <button className="quiz-modal__close" onClick={() => setModalOpen(false)}>
                <X size={20} />
              </button>
            </div>

            <form className="quiz-modal__body" onSubmit={handleSubmit}>
              <div className="quiz-form-group">
                <label className="quiz-form-label">
                  Question Title <span className="quiz-required">*</span>
                </label>
                <textarea
                  className="quiz-form-textarea"
                  placeholder="Enter the quiz question..."
                  value={formTitle}
                  onChange={e => setFormTitle(e.target.value)}
                  rows={3}
                />
              </div>

              <div className="quiz-form-group">
                <label className="quiz-form-label">
                  Answer Options <span className="quiz-required">*</span>
                </label>
                <p className="quiz-form-hint">Click the circle to mark the correct answer.</p>
                <div className="quiz-options-list">
                  {formOptions.map((opt, i) => (
                    <div key={i} className="quiz-option-row">
                      <button
                        type="button"
                        className={`quiz-option-radio ${formCorrectAnswer === opt && opt.trim() ? 'selected' : ''}`}
                        onClick={() => opt.trim() && setFormCorrectAnswer(opt)}
                        title="Mark as correct answer"
                      >
                        {formCorrectAnswer === opt && opt.trim() ? (
                          <Check size={12} />
                        ) : (
                          String.fromCharCode(65 + i)
                        )}
                      </button>
                      <input
                        type="text"
                        className="quiz-form-input"
                        placeholder={`Option ${String.fromCharCode(65 + i)}`}
                        value={opt}
                        onChange={e => {
                          const updated = [...formOptions];
                          if (formCorrectAnswer === formOptions[i]) {
                            setFormCorrectAnswer(e.target.value);
                          }
                          updated[i] = e.target.value;
                          setFormOptions(updated);
                        }}
                      />
                    </div>
                  ))}
                </div>
              </div>

              <div className="quiz-form-row">
                <div className="quiz-form-group">
                  <label className="quiz-form-label">Profession Category</label>
                  <select
                    className="quiz-form-select"
                    value={formCategory}
                    onChange={e => setFormCategory(e.target.value)}
                  >
                    <option value="Electrician">Electrician</option>
                    <option value="Plumber">Plumber</option>
                  </select>
                </div>

                <div className="quiz-form-group">
                  <label className="quiz-form-label">Difficulty Level</label>
                  <select
                    className="quiz-form-select"
                    value={formDifficulty}
                    onChange={e => setFormDifficulty(e.target.value)}
                  >
                    <option value="Easy">Easy</option>
                    <option value="Medium">Medium</option>
                    <option value="Hard">Hard</option>
                  </select>
                </div>
              </div>

              <div className="quiz-modal__footer">
                <button type="button" className="btn btn--ghost" onClick={() => setModalOpen(false)}>
                  Cancel
                </button>
                <button type="submit" className="btn btn--primary">
                  {editingQuestion ? 'Save Changes' : 'Create Question'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
