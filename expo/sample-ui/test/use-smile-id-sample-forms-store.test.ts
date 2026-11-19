import { smileIDSampleIdDetailsDefaults } from '../src/state/use-smile-id-sample-id-details';
import { useSmileIDSampleFormsStore } from '../src/state/use-smile-id-sample-forms-store';
import { KENYA, fixtureIdTypes } from './catalogue-fixtures';

const store = () => useSmileIDSampleFormsStore.getState();

describe('a product tap', () => {
  it("never carries the last run's ID details into the next", () => {
    store().setCountry(KENYA);
    store().setIdType(fixtureIdTypes('KE')[0]!);
    store().setIdNumber('12345678');

    store().startRun(null);

    expect(store().idDetails).toEqual(smileIDSampleIdDetailsDefaults);
  });
});

describe('a started flow', () => {
  it('holds the forms until the next product tap', () => {
    store().startRun(null);
    expect(store().flowStarted).toBe(false);

    store().markFlowStarted();
    expect(store().flowStarted).toBe(true);

    store().startRun(null);
    expect(store().flowStarted).toBe(false);
  });

  it('is forgotten on signing out', () => {
    store().markFlowStarted();

    store().clear();

    expect(store().flowStarted).toBe(false);
  });
});
