// @flow
import { useState, useEffect } from "react";
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
  if (Platform.OS === "android") {
    RNBluetoothManager.setBluetoothState(enable);
  }
};

export const useBluetoothStatus = () => {
  const [status, setStatus] = useState(undefined);
  const [isPending, setPending] = useState(true);

  useEffect(() => {
    const subscription = RNBluetoothManagerEventEmitter.addListener(BT_STATUS_EVENT, state => {
      const nativeState = Platform.OS === "ios" ? state : state.status;
      setStatus(nativeState === "on");
    });
    return () => {
      subscription.remove();
    };
  }, []);

  useEffect(() => {
    if (status !== undefined && isPending) {
      setPending(false);
    }
  }, [status]);

  return [status, isPending, setBluetoothState];
};
