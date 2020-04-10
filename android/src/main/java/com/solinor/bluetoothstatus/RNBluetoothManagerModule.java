package com.solinor.bluetoothstatus;

import android.bluetooth.BluetoothAdapter;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Handler;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.LifecycleEventListener;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;

public class RNBluetoothManagerModule extends ReactContextBaseJavaModule implements LifecycleEventListener {

    private final static String MODULE_NAME = "RNBluetoothManager";
    private final static String BT_STATUS_EVENT = "bluetoothStatus";
    private final static String BT_STATUS_PARAM = "status";
    private final static String BT_STATUS_ON = "on";
    private final static String BT_STATUS_OFF = "off";

    private BluetoothAdapter btAdapter;

    RNBluetoothManagerModule(@NonNull ReactApplicationContext reactContext) {
        super(reactContext);
    }

    private void sendEvent(ReactContext reactContext, @Nullable WritableMap params) {
        reactContext
                .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                .emit(RNBluetoothManagerModule.BT_STATUS_EVENT, params);
    }

    @Nullable
    private BroadcastReceiver receiver;

    @Override
    public void initialize() {
        super.initialize();
        receiver =  new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                final String action = intent.getAction();
                WritableMap params = Arguments.createMap();
                if (action != null && action.equals(BluetoothAdapter.ACTION_STATE_CHANGED)) {
                    final int state = intent.getIntExtra(BluetoothAdapter.EXTRA_STATE,
                            BluetoothAdapter.ERROR);
                    switch (state) {
                        case BluetoothAdapter.STATE_OFF:
                            params.putString(BT_STATUS_PARAM, BT_STATUS_OFF);
                            sendEvent(getReactApplicationContext(), params);
                            break;
                        case BluetoothAdapter.STATE_ON:
                            params.putString(BT_STATUS_PARAM, BT_STATUS_ON);
                            sendEvent(getReactApplicationContext(), params);
                            break;
                    }
                }
            }
        };

        getReactApplicationContext().addLifecycleEventListener(this);
        btAdapter = BluetoothAdapter.getDefaultAdapter();
        IntentFilter filter = new IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED);
        getReactApplicationContext().registerReceiver(receiver, filter);
    }

    @NonNull
    @Override
    public String getName() {
        return MODULE_NAME;
    }

    @ReactMethod
    public void getBluetoothState(Promise promise) {
        boolean isEnabled = false;
        if (btAdapter != null) {
            isEnabled = btAdapter.isEnabled();
        }
        promise.resolve(isEnabled);
    }

    @ReactMethod
    public void setBluetoothState(boolean enabled) {
        if  (btAdapter != null) {
            if (enabled) {
                btAdapter.enable();
            } else {
                btAdapter.disable();
            }
        }
    }

    @Override
    public void onHostResume() {
        Handler handler = new Handler();
        handler.postDelayed(new Runnable() {
            @Override
            public void run() {
                WritableMap params = Arguments.createMap();
                String enabled = btAdapter != null && btAdapter.isEnabled() ? BT_STATUS_ON : BT_STATUS_OFF;
                params.putString(BT_STATUS_PARAM, enabled);
                sendEvent(getReactApplicationContext(), params);

            }
        }, 10);
    }

    @Override
    public void onHostPause() { }

    @Override
    public void onHostDestroy() { }

    @Override
    public void onCatalystInstanceDestroy() {
        if (receiver != null) {
            getReactApplicationContext().unregisterReceiver(receiver);
        }
    }
}