import React from 'react';


const appContext = React.createContext(null);
const ContextProvider = appContext.Provider;
const ContextConsumer = appContext.Consumer;

export { ContextProvider, ContextConsumer };