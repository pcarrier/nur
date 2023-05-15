enum StoreIteratorDecision {
    ContinueForward,
    ContinueBackward,
    Stop,
}

interface Store {
    clear(): void;
    get(key: ArrayBufferView): ArrayBuffer | null;
    set(key: ArrayBufferView, value: ArrayBufferView): void;
    iterate(callback: (key: ArrayBufferView, value: ArrayBufferView) => StoreIteratorDecision, from: ArrayBufferView | undefined): void;
}

interface Nur {
    store: Store;
    fetch: typeof fetch;
    readBytes(): Uint8Array;
    readLn(): string;
    writeBytes(bytes: ArrayBufferView): void;
    writeStr(str: string): void;
    writeLn(str: string): void;
}

const nur: Nur = {
    store: {
        clear() {},
        get(key) { return null; },
        set(key, value) {},
        iterate(cb, from) {},
    },
    fetch,
    readBytes() { return new Uint8Array(0); },
    readLn() { return "" },
    writeBytes(bytes: Uint8Array) {},
    writeStr(str: string) {},
    writeLn(str: string) {},
};

export default nur;