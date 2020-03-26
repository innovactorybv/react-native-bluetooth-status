// @flow
import { useState, useEffect, useCallback } from "react";
import { Platform } from "react-native";
import {
  NativeModules,
  DeviceEventEmitter,
  NativeEventEmitter
} from "react-native";
import waitUntil from "@cs125/wait-until";

const { RNBluetoothManager } = NativeModules;
const RNBluetoothManagerEventEmitter = new NativeEventEmitter(RNBluetoothManager);

const BT_STATUS_EVENT = "bluetoothStatus";
class BluetoothManager {
  subscription: mixed;
  bluetoothState:
    | "unknown"
    | "resetting"
    | "unsupported"
    | "unauthorized"
    | "off"
    | "on"
    | "unknown";
  listener: function;
  subscription: function;

  startSubscribeIfNeeded() {
    if (this.subscription) return // already subscribed
    this.subscription = RNBluetoothManagerEventEmitter.addListener(BT_STATUS_EVENT, state => {
      const nativeState = Platform.OS === "ios" ? state : state.status;
      this.bluetoothState = nativeState;
      if (this.listener) {
        this.listener(this.bluetoothState === "on");
      }
    })
  }

  unsubscrubeIfIfNoActiveListener() {
    if (!this.subscription) return; // already unsubscribed
    if (this.listener) return; // still have active listeners
    this.subscription.remove();
    this.subscription = undefined;
    this.bluetoothState = undefined
  }

  addListener(listener: function) {
    this.startSubscribeIfNeeded()
    this.listener = listener;
  }

  removeListener() {
    this.listener = undefined;
    this.unsubscrubeIfIfNoActiveListener()
  }

  async state() {
    if (Platform.OS === "android") {
      return RNBluetoothManager.getBluetoothState()
    }
    return new Promise((resolve, reject) => {
      waitUntil()
        .interval(100)
        .times(10)
        .condition(() => {
          this.startSubscribeIfNeeded()
          return this.bluetoothState !== undefined;
        })
        .done(() => {
          resolve(this.bluetoothState === "on");
          this.unsubscrubeIfIfNoActiveListener();
        });
    });
  }

  enable(enabled: boolean = true) {
    RNBluetoothManager.setBluetoothState(enabled);
  }

  async disable() {
    return this.enable(false);
  }
}

export const BluetoothStatus = new BluetoothManager();

const setBluetoothState = (enable: boolean = true) => {
  RNBluetoothManager.setBluetoothState(enable);
};

export const useBluetoothStatus = () => {
  const [status, setStatus] = useState(undefined)

  useEffect(() => {
    const subscription = RNBluetoothManagerEventEmitter.addListener(BT_STATUS_EVENT, state => {
      const nativeState = Platform.OS === "ios" ? state : state.status;
      
      // ignore for in-flight state changes
      if (!nativeState ||  nativeState === "unknown" || nativeState === "resetting") return

      setStatus({
        enabled: nativeState === "on",
        granted: nativeState === "on" || nativeState === "off",
      })
    });

    // Android doesn't send status when addListener is called so
    // we actively fetch the current power status
    if (Platform.OS === "android") {
      RNBluetoothManager.getBluetoothState().then(enabled => {
        setStatus({
          enabled: enabled,
          granted: true, // android has no bluetooth permission
        })
      })
    }

    return () => {
      subscription.remove();
    };
  }, []);

  // btStatus, granted, pending, 
  if (!status) return [undefined, undefined, true, setBluetoothState]
  return [status.enabled, status.granted, false, setBluetoothState]
};
