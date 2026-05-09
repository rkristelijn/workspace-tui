// IT-specifieke reframing: van force naar power
export const IT_REFRAMING: Record<string, string> = {
  problem: 'challenge',
  issue: 'opportunity',
  blocker: 'dependency',
  blocked: 'waiting on',
  bug: 'unexpected behavior',
  broken: 'needs attention',
  failed: 'learned',
  failure: 'learning',
  error: 'signal',
  crash: 'restart needed',
  'technical debt': 'refactoring opportunity',
  'legacy code': 'existing system',
  hack: 'workaround',
  impossible: 'challenging',
  "can't": 'exploring how to',
  stuck: 'investigating',
  bloated: 'feature-rich',
  slow: 'optimizable',
  messy: 'evolving',
};

export interface FramingIssue {
  word: string;
  suggestion: string;
  line: number;
  column: number;
}

export function checkPositiveFraming(content: string): FramingIssue[] {
  const issues: FramingIssue[] = [];
  const lines = content.split('\n');

  lines.forEach((line, lineIndex) => {
    const lower = line.toLowerCase();

    Object.entries(IT_REFRAMING).forEach(([negative, positive]) => {
      const regex = new RegExp(`\\b${negative}\\b`, 'gi');
      let match;

      while ((match = regex.exec(line)) !== null) {
        issues.push({
          word: match[0],
          suggestion: positive,
          line: lineIndex + 1,
          column: match.index + 1,
        });
      }
    });
  });

  return issues;
}
