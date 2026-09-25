import {
  smileIDSampleCountries,
  smileIDSampleIdDetailsDefaults,
  smileIDSampleIdTypes,
} from '../src/state/use-smile-id-sample-id-details';
import { useSmileIDSampleFormsStore } from '../src/state/use-smile-id-sample-forms-store';

const store = () => useSmileIDSampleFormsStore.getState();

describe('a product tap', () => {
  it("never carries the last run's ID details into the next", () => {
    store().setCountry(smileIDSampleCountries[0]!);
    store().setIdType(smileIDSampleIdTypes[0]!);
    store().setIdNumber('12345678');

    store().startRun(null);

    expect(store().idDetails).toEqual(smileIDSampleIdDetailsDefaults);
  });
});
