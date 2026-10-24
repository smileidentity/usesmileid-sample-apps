import { smileIDSampleFlowRoutes, type UseSmileIDSampleFlowRoute } from '@smileid/sample-ui';

/// A deep link as the graph reads it: the `path` it opens and, for the run, the `route` it asked for.
export type UseSmileIDSampleLink = {
  readonly path: string;
  readonly route?: UseSmileIDSampleFlowRoute;
};

/// The graph names the full-screen run apart, as this suffix on the run's path.
const fullScreenSuffix = '-fullscreen';

/// The path and query of `url`, with the app's own scheme and any host folded into the path.
const partsOf = (url: string): { path: string; query: URLSearchParams } => {
  const withoutScheme = url.replace(/^[a-z][a-z0-9+.-]*:(\/\/)?/i, '');
  const [path = '', query = ''] = withoutScheme.split('?', 2);
  return {
    path: path
      .split('#', 1)[0]!
      .split('/')
      .filter((segment) => segment.length > 0)
      .join('/'),
    query: new URLSearchParams(query.split('#', 1)[0]),
  };
};

/// The graph link `url` opens, or null for the plain launch: the paths are `spec/njia-graph.json`'s, the scheme the app's own.
export const smileIDSampleLinkOf = (url: string | null): UseSmileIDSampleLink | null => {
  if (url === null) return null;
  const { path, query } = partsOf(url);
  if (path.length === 0) return null;
  const segments = path.split('/');
  if (segments.length !== 3 || segments[0] !== 'flow' || segments[2] !== 'run') return { path };
  // One URL, two presentations: `spec/routes.json` defaults the run to full screen, which the graph names apart.
  const asked = query.get('route');
  const route = smileIDSampleFlowRoutes.find((candidate) => candidate === asked) ?? 'fullscreen';
  return { path: route === 'fullscreen' ? `${path}${fullScreenSuffix}` : path, route };
};

/// The product a `flow/…` link runs, as its second segment names it.
export const smileIDSampleLinkProductId = (link: UseSmileIDSampleLink): string | undefined => {
  const segments = link.path.split('/');
  return segments.length >= 2 && segments[0] === 'flow' ? segments[1] : undefined;
};
