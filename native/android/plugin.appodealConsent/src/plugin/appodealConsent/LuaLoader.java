package plugin.appodealConsent;

import android.app.Activity;

import com.ansca.corona.CoronaEnvironment;
import com.ansca.corona.CoronaLua;
import com.ansca.corona.CoronaRuntime;
import com.ansca.corona.CoronaRuntimeTask;
import com.ansca.corona.CoronaRuntimeTaskDispatcher;
import com.appodeal.consent.ConsentManager;
import com.appodeal.consent.ConsentManagerError;
import com.appodeal.consent.OnConsentFormDismissedListener;
import com.appodeal.consent.PrivacyOptionsRequirementStatus;
import com.google.android.ump.ConsentDebugSettings;
import com.google.android.ump.ConsentForm;
import com.google.android.ump.ConsentInformation;
import com.google.android.ump.ConsentRequestParameters;
import com.google.android.ump.FormError;
import com.google.android.ump.UserMessagingPlatform;
import com.naef.jnlua.JavaFunction;
import com.naef.jnlua.LuaState;
import com.naef.jnlua.NamedJavaFunction;

/**
 * Exposes Appodeal 4's privacy options form (ConsentManager) to Lua, which the
 * official Solar2D Appodeal plugin doesn't do. Appodeal itself must be included
 * through plugin.appodeal.base, which provides the consent classes at runtime.
 *
 * local consent = require( "plugin.appodealConsent" )
 * consent.getPrivacyOptionsStatus()      -- "Required", "NotRequired" or "Unknown"
 * consent.showPrivacyOptionsForm( listener )  -- listener gets { name="privacyOptions", isError, errorMessage }
 *
 * Testing only (never call in release builds):
 * consent.showTestPrivacyOptionsForm( listener ) -- uses Google UMP with debug geography forced to the EEA, so the
 *     consent form (first time) or privacy options form (afterwards) shows on any device. Appodeal 4.3 has no
 *     debug geography of its own (added in Appodeal 4.4).
 */
public class LuaLoader implements JavaFunction {
	private static final String EVENT_NAME = "privacyOptions";

	@Override
	public int invoke(LuaState L) {
		NamedJavaFunction[] luaFunctions = new NamedJavaFunction[] {
			new GetPrivacyOptionsStatus(),
			new ShowPrivacyOptionsForm(),
			new ShowTestPrivacyOptionsForm(),
		};
		String libName = L.toString(1);
		L.register(libName, luaFunctions);
		return 1;
	}

	private static class GetPrivacyOptionsStatus implements NamedJavaFunction {
		@Override
		public String getName() {
			return "getPrivacyOptionsStatus";
		}

		@Override
		public int invoke(LuaState L) {
			String status = "Unknown";
			try {
				PrivacyOptionsRequirementStatus result = ConsentManager.getPrivacyOptionsRequirementStatus();
				if (result != null) {
					status = result.name();
				}
			} catch (Throwable t) {
				// Appodeal not initialised yet, or consent classes missing
			}
			L.pushString(status);
			return 1;
		}
	}

	private static class ShowPrivacyOptionsForm implements NamedJavaFunction {
		@Override
		public String getName() {
			return "showPrivacyOptionsForm";
		}

		@Override
		public int invoke(LuaState L) {
			final int listenerRef = CoronaLua.isListener(L, 1, EVENT_NAME) ? CoronaLua.newRef(L, 1) : CoronaLua.REFNIL;
			final CoronaRuntimeTaskDispatcher dispatcher = new CoronaRuntimeTaskDispatcher(L);
			final Activity activity = CoronaEnvironment.getCoronaActivity();
			if (activity == null) {
				dispatchResult(dispatcher, listenerRef, "No active Corona activity");
				return 0;
			}

			activity.runOnUiThread(new Runnable() {
				@Override
				public void run() {
					try {
						ConsentManager.showPrivacyOptionsForm(activity, new OnConsentFormDismissedListener() {
							@Override
							public void onConsentFormDismissed(ConsentManagerError error) {
								dispatchResult(dispatcher, listenerRef, error != null ? String.valueOf(error.getMessage()) : null);
							}
						});
					} catch (Throwable t) {
						dispatchResult(dispatcher, listenerRef, String.valueOf(t.getMessage()));
					}
				}
			});
			return 0;
		}
	}

	private static class ShowTestPrivacyOptionsForm implements NamedJavaFunction {
		@Override
		public String getName() {
			return "showTestPrivacyOptionsForm";
		}

		@Override
		public int invoke(LuaState L) {
			final int listenerRef = CoronaLua.isListener(L, 1, EVENT_NAME) ? CoronaLua.newRef(L, 1) : CoronaLua.REFNIL;
			final CoronaRuntimeTaskDispatcher dispatcher = new CoronaRuntimeTaskDispatcher(L);
			final Activity activity = CoronaEnvironment.getCoronaActivity();
			if (activity == null) {
				dispatchResult(dispatcher, listenerRef, "No active Corona activity");
				return 0;
			}

			activity.runOnUiThread(new Runnable() {
				@Override
				public void run() {
					try {
						ConsentDebugSettings debugSettings = new ConsentDebugSettings.Builder(activity)
							.setDebugGeography(ConsentDebugSettings.DebugGeography.DEBUG_GEOGRAPHY_EEA)
							.setForceTesting(true)
							.build();
						ConsentRequestParameters params = new ConsentRequestParameters.Builder()
							.setConsentDebugSettings(debugSettings)
							.build();
						final ConsentInformation info = UserMessagingPlatform.getConsentInformation(activity);
						final ConsentForm.OnConsentFormDismissedListener onDismissed = new ConsentForm.OnConsentFormDismissedListener() {
							@Override
							public void onConsentFormDismissed(FormError error) {
								dispatchResult(dispatcher, listenerRef, error != null ? error.getMessage() : null);
							}
						};
						info.requestConsentInfoUpdate(activity, params,
							new ConsentInformation.OnConsentInfoUpdateSuccessListener() {
								@Override
								public void onConsentInfoUpdateSuccess() {
									if (info.getConsentStatus() == ConsentInformation.ConsentStatus.REQUIRED) {
										UserMessagingPlatform.loadAndShowConsentFormIfRequired(activity, onDismissed);
									} else {
										UserMessagingPlatform.showPrivacyOptionsForm(activity, onDismissed);
									}
								}
							},
							new ConsentInformation.OnConsentInfoUpdateFailureListener() {
								@Override
								public void onConsentInfoUpdateFailure(FormError error) {
									dispatchResult(dispatcher, listenerRef, error != null ? error.getMessage() : "Consent info update failed");
								}
							});
					} catch (Throwable t) {
						dispatchResult(dispatcher, listenerRef, String.valueOf(t.getMessage()));
					}
				}
			});
			return 0;
		}
	}

	private static void dispatchResult(CoronaRuntimeTaskDispatcher dispatcher, final int listenerRef, final String errorMessage) {
		if (listenerRef == CoronaLua.REFNIL) {
			return;
		}
		dispatcher.send(new CoronaRuntimeTask() {
			@Override
			public void executeUsing(CoronaRuntime runtime) {
				LuaState L = runtime.getLuaState();
				try {
					CoronaLua.newEvent(L, EVENT_NAME);
					L.pushBoolean(errorMessage != null);
					L.setField(-2, "isError");
					if (errorMessage != null) {
						L.pushString(errorMessage);
						L.setField(-2, "errorMessage");
					}
					CoronaLua.dispatchEvent(L, listenerRef, 0);
				} catch (Exception e) {
					e.printStackTrace();
				} finally {
					CoronaLua.deleteRef(L, listenerRef);
				}
			}
		});
	}
}
