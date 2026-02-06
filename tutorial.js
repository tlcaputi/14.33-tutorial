// 14.33 Tutorial JavaScript
//
// This file handles:
// 1. Language switching (Stata/R/Python) - both per-block and global
// 2. Code copy functionality
// 3. Mobile sidebar toggle
// 4. Collapsible nav sections
// 5. Active section highlighting on scroll
// 6. Stata syntax highlighting for Prism
//
// Key selectors:
// - .lang-toggle-btns button : Global language toggle in sidebar
// - .code-tab : Per-block language tabs
// - .code-content.stata/r/python : Code blocks for each language
// - .mobile-menu-btn : Hamburger button for mobile sidebar
//
// Language preference is saved to localStorage as 'preferredLang'

// ========== STATA SYNTAX HIGHLIGHTING FOR PRISM ==========
// Prism doesn't have built-in Stata support, so we define it here
if (typeof Prism !== 'undefined') {
  Prism.languages.stata = {
    'comment': [
      { pattern: /\/\/.*/, greedy: true },
      { pattern: /\/\*[\s\S]*?\*\//, greedy: true },
      { pattern: /^\s*\*.*$/m, greedy: true }
    ],
    'string': {
      pattern: /"[^"]*"|`"[^"]*"'|'[^']*'/,
      greedy: true
    },
    'keyword': /\b(?:if|else|while|forvalues|foreach|in|of|local|global|gen|generate|replace|drop|keep|merge|append|save|use|clear|set|display|di|summarize|sum|tabulate|tab|regress|reg|xi|areg|xtreg|ivregress|logit|probit|xtlogit|xtprobit|egen|collapse|reshape|encode|decode|destring|tostring|rename|order|sort|gsort|by|bysort|capture|cap|quietly|qui|noisily|preserve|restore|tempfile|tempvar|tempname|program|end|return|ereturn|matrix|scalar|assert|count|describe|des|list|browse|edit|insheet|outsheet|import|export|delimited|excel|copy|unzipfile|net|ssc|install|help|search|findit|log|cmdlog|graph|twoway|scatter|line|histogram|kdensity|bar|pie|export|scheme|title|xtitle|ytitle|xlabel|ylabel|legend|note|text|name|saving|replace|append|as|using|varlist|newlist|numlist|anything|options|ado|class|anova|anova|manova|test|lincom|nlcom|margins|contrast|pwcompare|estat|predict|vce|robust|cluster|absorb|noconstant|nocons|level|detail|missing|label|variable|value|define|values|modify|dir|drop|list|copy|save)\b/,
    'function': /\b(?:abs|ceil|floor|int|ln|log|log10|max|min|mod|round|sign|sqrt|exp|sum|mean|sd|var|count|rowmean|rowsd|rowmin|rowmax|rowtotal|rownonmiss|cond|inlist|inrange|missing|strlen|substr|subinstr|upper|lower|proper|trim|ltrim|rtrim|strpos|word|wordcount|real|string|date|mdy|dmy|ymd|year|month|day|week|dow|doy|quarter|halfyear|daily|weekly|monthly|quarterly|halfyearly|yearly|clock|hours|minutes|seconds|Cmdyhms|hms|td|tc|tC|tw|tm|tq|th|ty|runiform|rnormal|rbinomial|rpoisson|_n|_N|_pi|_rc|c|r|e|s|b|n)\b/,
    'number': /\b\d+\.?\d*\b/,
    'operator': /[<>!=]=?|[+\-*\/^&|~]|\.\.|\/\/\//,
    'punctuation': /[(),;`']/,
    'macro': /`[^']*'|\$\w+/,
    'variable': /\b[a-zA-Z_]\w*\b/
  };
}

document.addEventListener('DOMContentLoaded', function() {

  // Re-run Prism highlighting now that Stata language is defined
  if (typeof Prism !== 'undefined') {
    Prism.highlightAll();
  }

  // ========== TAB SWITCHING ==========

  // Handle individual code block tab clicks
  document.querySelectorAll('.code-tab').forEach(tab => {
    tab.addEventListener('click', function() {
      const lang = this.dataset.lang;
      const block = this.closest('.code-block');

      // Update tab active states
      block.querySelectorAll('.code-tab').forEach(t => t.classList.remove('active'));
      this.classList.add('active');

      // Show/hide code content
      block.querySelectorAll('.code-content').forEach(c => c.classList.remove('active'));
      block.querySelector(`.code-content.${lang}`).classList.add('active');
    });
  });

  // Global language preference
  const savedLang = localStorage.getItem('preferredLang') || 'stata';
  setGlobalLanguage(savedLang);

  // Global toggle buttons in sidebar
  // Matches buttons inside .lang-toggle-btns container (see focused-nav.liquid)
  document.querySelectorAll('.lang-toggle-btns button').forEach(btn => {
    btn.addEventListener('click', function() {
      const lang = this.dataset.lang;
      setGlobalLanguage(lang);
      localStorage.setItem('preferredLang', lang);
    });
  });

  function setGlobalLanguage(lang) {
    // Update code blocks that have multiple language options
    // Leave single-language blocks (terminal, shell) alone
    document.querySelectorAll('.code-block').forEach(block => {
      const hasStata = block.querySelector('.code-content.stata');
      const hasR = block.querySelector('.code-content.r');
      const hasPython = block.querySelector('.code-content.python');

      // Count how many languages this block supports
      const langCount = [hasStata, hasR, hasPython].filter(Boolean).length;

      // Only toggle if block has multiple languages
      if (langCount >= 2) {
        // Check if the requested language is available in this block
        const hasRequestedLang = block.querySelector(`.code-content.${lang}`);

        if (hasRequestedLang) {
          block.querySelectorAll('.code-tab').forEach(t => {
            t.classList.toggle('active', t.dataset.lang === lang);
          });
          block.querySelectorAll('.code-content').forEach(c => {
            c.classList.toggle('active', c.classList.contains(lang));
          });
        }
        // If requested lang not available, keep current selection
      }
      // Single-language blocks stay as-is (always visible)
    });

    // Update global toggle buttons
    document.querySelectorAll('.lang-toggle-btns button').forEach(btn => {
      btn.classList.toggle('active', btn.dataset.lang === lang);
    });
  }

  // ========== QUIZ CHECK ANSWER ==========

  window.checkAnswer = function(btn, isCorrect) {
    const quiz = btn.closest('.section-quiz');
    const feedback = quiz.querySelector('.quiz-feedback');

    // Reset all buttons in this quiz
    quiz.querySelectorAll('button').forEach(b => {
      b.style.background = 'white';
      b.style.borderColor = 'var(--border)';
    });

    if (isCorrect) {
      btn.style.background = '#d4edda';
      btn.style.borderColor = '#28a745';
      feedback.textContent = '✓ Correct!';
      feedback.style.background = '#d4edda';
      feedback.style.color = '#155724';
    } else {
      btn.style.background = '#f8d7da';
      btn.style.borderColor = '#dc3545';
      feedback.textContent = '✗ Not quite. Try again!';
      feedback.style.background = '#f8d7da';
      feedback.style.color = '#721c24';
    }
    feedback.style.display = 'block';
  };

  // ========== COPY TO CLIPBOARD ==========

  window.copyCode = function(btn) {
    const block = btn.closest('.code-block');
    const activeCode = block.querySelector('.code-content.active code');
    const text = activeCode.textContent;

    navigator.clipboard.writeText(text).then(() => {
      btn.textContent = 'Copied!';
      btn.classList.add('copied');
      setTimeout(() => {
        btn.textContent = 'Copy';
        btn.classList.remove('copied');
      }, 2000);
    }).catch(err => {
      console.error('Failed to copy:', err);
    });
  };

  // ========== MOBILE SIDEBAR ==========

  const sidebar = document.querySelector('.sidebar');
  const overlay = document.querySelector('.sidebar-overlay');
  const menuBtn = document.querySelector('.mobile-menu-btn');

  if (menuBtn) {
    menuBtn.addEventListener('click', () => {
      sidebar.classList.toggle('open');
      overlay.classList.toggle('open');
    });
  }

  if (overlay) {
    overlay.addEventListener('click', () => {
      sidebar.classList.remove('open');
      overlay.classList.remove('open');
    });
  }

  // ========== COLLAPSIBLE SIDEBAR SECTIONS ==========

  document.querySelectorAll('.nav-section-header').forEach(header => {
    header.addEventListener('click', function() {
      const section = this.closest('.nav-section');

      // Toggle this section
      section.classList.toggle('open');
    });
  });

  // ========== ACTIVE SECTION HIGHLIGHTING ==========

  const sections = document.querySelectorAll('.tutorial-section[id]');
  // Support both collapsible nav (.nav-section-content) and flat nav (.nav-links)
  const navLinks = document.querySelectorAll('.nav-section-content a, .nav-links a');

  function updateActiveNav() {
    let currentSection = '';

    sections.forEach(section => {
      const sectionTop = section.offsetTop - 100;
      if (window.scrollY >= sectionTop) {
        currentSection = section.getAttribute('id');
      }
    });

    navLinks.forEach(link => {
      link.classList.remove('active');
      // Also remove background highlight for flat nav style
      link.style.background = '';
      if (link.getAttribute('href') === `#${currentSection}`) {
        link.classList.add('active');
        // Add background for flat nav links (they use inline styles)
        if (link.closest('.nav-links')) {
          link.style.background = 'var(--bg-subtle)';
        }
      }
    });
  }

  window.addEventListener('scroll', updateActiveNav);
  updateActiveNav();

  // ========== SMOOTH SCROLL ==========

  document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function(e) {
      e.preventDefault();
      const target = document.querySelector(this.getAttribute('href'));
      if (target) {
        target.scrollIntoView({ behavior: 'smooth', block: 'start' });

        // Close mobile menu if open
        sidebar?.classList.remove('open');
        overlay?.classList.remove('open');
      }
    });
  });

});
