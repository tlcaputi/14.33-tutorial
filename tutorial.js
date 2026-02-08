// 14.33 Tutorial JavaScript — Material-style
//
// Handles:
// 1. Language switching (Stata/R/Python)
// 2. Code copy
// 3. Mobile sidebar toggle
// 4. Nav group collapsing
// 5. Active section highlighting (left nav + right TOC)
// 6. Stata syntax highlighting

// ========== STATA SYNTAX HIGHLIGHTING ==========
if (typeof Prism !== 'undefined') {
  Prism.languages.stata = {
    'comment': [
      { pattern: /\/\/.*/, greedy: true },
      { pattern: /\/\*[\s\S]*?\*\//, greedy: true },
      { pattern: /^\s*\*.*$/m, greedy: true }
    ],
    'string': { pattern: /"[^"]*"|`"[^"]*"'|'[^']*'/, greedy: true },
    'keyword': /\b(?:if|else|while|forvalues|foreach|in|of|local|global|gen|generate|replace|drop|keep|merge|append|save|use|clear|set|display|di|summarize|sum|tabulate|tab|regress|reg|xi|areg|xtreg|ivregress|logit|probit|xtlogit|xtprobit|egen|collapse|reshape|encode|decode|destring|tostring|rename|order|sort|gsort|by|bysort|capture|cap|quietly|qui|noisily|preserve|restore|tempfile|tempvar|tempname|program|end|return|ereturn|matrix|scalar|assert|count|describe|des|list|browse|edit|insheet|outsheet|import|export|delimited|excel|copy|unzipfile|net|ssc|install|help|search|findit|log|cmdlog|graph|twoway|scatter|line|histogram|kdensity|bar|pie|export|scheme|title|xtitle|ytitle|xlabel|ylabel|legend|note|text|name|saving|replace|append|as|using|varlist|newlist|numlist|anything|options|ado|class|anova|manova|test|lincom|nlcom|margins|contrast|pwcompare|estat|predict|vce|robust|cluster|absorb|noconstant|nocons|level|detail|missing|label|variable|value|define|values|modify|dir|drop|list|copy|save)\b/,
    'function': /\b(?:abs|ceil|floor|int|ln|log|log10|max|min|mod|round|sign|sqrt|exp|sum|mean|sd|var|count|rowmean|rowsd|rowmin|rowmax|rowtotal|rownonmiss|cond|inlist|inrange|missing|strlen|substr|subinstr|upper|lower|proper|trim|ltrim|rtrim|strpos|word|wordcount|real|string|date|mdy|dmy|ymd|year|month|day|week|dow|doy|quarter|halfyear|daily|weekly|monthly|quarterly|halfyearly|yearly|clock|hours|minutes|seconds|Cmdyhms|hms|td|tc|tC|tw|tm|tq|th|ty|runiform|rnormal|rbinomial|rpoisson|_n|_N|_pi|_rc|c|r|e|s|b|n)\b/,
    'number': /\b\d+\.?\d*\b/,
    'operator': /[<>!=]=?|[+\-*\/^&|~]|\.\.|\/\/\//,
    'punctuation': /[(),;`']/,
    'macro': /`[^']*'|\$\w+/,
    'variable': /\b[a-zA-Z_]\w*\b/
  };
}

document.addEventListener('DOMContentLoaded', function() {

  if (typeof Prism !== 'undefined') Prism.highlightAll();

  // ========== TAB SWITCHING ==========
  document.querySelectorAll('.code-tab').forEach(tab => {
    tab.addEventListener('click', function() {
      const lang = this.dataset.lang;
      const block = this.closest('.code-block');
      block.querySelectorAll('.code-tab').forEach(t => t.classList.remove('active'));
      this.classList.add('active');
      block.querySelectorAll('.code-content').forEach(c => c.classList.remove('active'));
      block.querySelector(`.code-content.${lang}`).classList.add('active');
    });
  });

  // Global language preference
  const savedLang = localStorage.getItem('preferredLang') || 'stata';
  setGlobalLanguage(savedLang);

  document.querySelectorAll('.lang-toggle-btns button').forEach(btn => {
    btn.addEventListener('click', function() {
      const lang = this.dataset.lang;
      setGlobalLanguage(lang);
      localStorage.setItem('preferredLang', lang);
    });
  });

  function setGlobalLanguage(lang) {
    document.querySelectorAll('.code-block').forEach(block => {
      const hasStata = block.querySelector('.code-content.stata');
      const hasR = block.querySelector('.code-content.r');
      const hasPython = block.querySelector('.code-content.python');
      const langCount = [hasStata, hasR, hasPython].filter(Boolean).length;
      if (langCount >= 2) {
        const hasRequestedLang = block.querySelector(`.code-content.${lang}`);
        if (hasRequestedLang) {
          block.querySelectorAll('.code-tab').forEach(t => t.classList.toggle('active', t.dataset.lang === lang));
          block.querySelectorAll('.code-content').forEach(c => c.classList.toggle('active', c.classList.contains(lang)));
        }
      }
    });
    document.querySelectorAll('.lang-toggle-btns button').forEach(btn => {
      btn.classList.toggle('active', btn.dataset.lang === lang);
    });
  }

  // ========== QUIZ ==========
  window.checkAnswer = function(btn, isCorrect) {
    const quiz = btn.closest('.section-quiz');
    const feedback = quiz.querySelector('.quiz-feedback');
    quiz.querySelectorAll('button').forEach(b => { b.style.background = 'white'; b.style.borderColor = 'var(--border)'; });
    if (isCorrect) {
      btn.style.background = '#d4edda'; btn.style.borderColor = '#28a745';
      feedback.textContent = '\u2713 Correct!'; feedback.style.background = '#d4edda'; feedback.style.color = '#155724';
    } else {
      btn.style.background = '#f8d7da'; btn.style.borderColor = '#dc3545';
      feedback.textContent = '\u2717 Not quite. Try again!'; feedback.style.background = '#f8d7da'; feedback.style.color = '#721c24';
    }
    feedback.style.display = 'block';
  };

  // ========== COPY ==========
  window.copyCode = function(btn) {
    const block = btn.closest('.code-block');
    const activeCode = block.querySelector('.code-content.active code');
    navigator.clipboard.writeText(activeCode.textContent).then(() => {
      btn.textContent = 'Copied!'; btn.classList.add('copied');
      setTimeout(() => { btn.textContent = 'Copy'; btn.classList.remove('copied'); }, 2000);
    });
  };

  // ========== MOBILE SIDEBAR ==========
  const sidebar = document.querySelector('.sidebar');
  const overlay = document.querySelector('.sidebar-overlay');

  // Material header hamburger
  const menuBtn = document.querySelector('.md-mobile-menu-btn');
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

  // ========== NAV GROUP TOGGLING ==========
  document.querySelectorAll('.md-nav__group-title').forEach(title => {
    title.addEventListener('click', function() {
      const group = this.closest('.md-nav__group');
      group.classList.toggle('md-nav__group--active');
      this.setAttribute('aria-expanded', group.classList.contains('md-nav__group--active'));
    });
    title.addEventListener('keydown', function(e) {
      if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); this.click(); }
    });
  });

  // ========== SCROLL-BASED HIGHLIGHTING ==========
  const sections = document.querySelectorAll('.tutorial-section[id]');
  const tocLinks = document.querySelectorAll('.md-toc__link');

  function updateActiveSection() {
    let currentId = '';
    sections.forEach(section => {
      if (window.scrollY >= section.offsetTop - 120) {
        currentId = section.getAttribute('id');
      }
    });

    // Highlight right TOC
    tocLinks.forEach(link => {
      const href = link.getAttribute('href');
      link.classList.toggle('active', href === `#${currentId}`);
    });
  }

  if (sections.length > 0) {
    window.addEventListener('scroll', updateActiveSection, { passive: true });
    updateActiveSection();
  }

  // ========== SMOOTH SCROLL ==========
  document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function(e) {
      e.preventDefault();
      const target = document.querySelector(this.getAttribute('href'));
      if (target) {
        target.scrollIntoView({ behavior: 'smooth', block: 'start' });
        sidebar?.classList.remove('open');
        overlay?.classList.remove('open');
      }
    });
  });

});
