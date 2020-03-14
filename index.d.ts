declare module "react-native-bluetooth-status" {
  namespace BluetoothStatus {
    /**
     * Returns a promise, which will return a boolean value, true if bluetooth is available, false if unavailable.
     */
    export function state(): Promise<boolean>
    /**
     * Set the bluetooth status. On android it can be toggled on / off using the enabled parameter. On iOS this method can be used to prompt for permission and/or enable bluetooth.
     * @param enableBluetooth Android: Boolean flag that determines the new status of bluetooth. On iOS this parameter is ignored.
     */
    export function enable(enableBluetooth: boolean = true): Promise<boolean>

    /**
     * Add listener that is called when BT availability status changes
     * @param callback called when BT status changes, with the new BT on/off status (true / false).
     */
    export function addListener(callback: (enabled: boolean) => void): void
    /**
     * Removes listener.
     */
    export function removeListener(): void
  }

  /**
   * Hook that return the following array:
   * ```
   * [
   *  btStatus: boolean - Current bluetooth status. Starts undefined, but updated asynchronously right away. Updated automatically if status changes.
   *  btGranted: boolean - Current bluetooth permission granted status. Starts undefined, but updated asynchronously right away. Updated automatically if status changes.
   *  isPending: boolean - Starts at true and after getting first Bluetooth status, is set to false. Helps to know when btStatus / btGranted is not undefined anymore.
   *  setBluetooth: boolean - Takes boolean parameter (defaults to true) to select the operation (Android only). On iOS this method can be used to prompt for permission and/or enable bluetooth.
   * ]
   * ```
   */
  export function useBluetoothStatus(): [
    boolean | undefined,
    boolean | undefined,
    boolean,
    (enabled: boolean = true) => void
  ]
}
